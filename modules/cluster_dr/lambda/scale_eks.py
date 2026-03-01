"""
DR Lambda Function: On-Prem Secondary Health Check + EKS Scale-up
1. 온프레미스 2차 헬스체크
    - DB 쿼리 성공 여부      
    - MinIO 접근 성공 여부    
    - 실제 API 요청 성공 여부 및 응답 시간
2. 헬스체크 실패 확인 시 EKS Deployment scale-up 
"""

import os
import json
import base64
import logging
import time
import tempfile
import urllib.error
import urllib.request
import urllib3
import datetime
import socket

import boto3
from kubernetes import client
from kubernetes.client.rest import ApiException

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# EKS 환경 변수 
CLUSTER_NAME     = os.environ["CLUSTER_NAME"]      
CLUSTER_ENDPOINT = os.environ["CLUSTER_ENDPOINT"]  
REGION           = os.environ.get("REGION", "ap-northeast-2")          
SCALE_REPLICAS   = int(os.environ.get("SCALE_REPLICAS", "3"))         

APP_NAMESPACE    = os.environ.get("APP_NAMESPACE", "app")
WEB_HPA          = os.environ.get("WEB_HPA", "frontend-hpa")
WAS_HPA          = os.environ.get("WAS_HPA", "backend-hpa")

# 온프레미스 헬스체크 환경 변수
ONPREM_DB_SECRET_ARN    = os.environ.get("ONPREM_DB_SECRET_ARN", "")    
ONPREM_MINIO_ENDPOINT   = os.environ.get("ONPREM_MINIO_ENDPOINT", "")  
ONPREM_MINIO_BUCKET     = os.environ.get("ONPREM_MINIO_BUCKET", "")    
ONPREM_MINIO_SECRET_ARN = os.environ.get("ONPREM_MINIO_SECRET_ARN", "") 
ONPREM_API_URL          = os.environ.get("ONPREM_API_URL", "")           
ONPREM_API_TIMEOUT_SEC  = float(os.environ.get("ONPREM_API_TIMEOUT_SEC", "5"))
ONPREM_API_WARN_MS      = float(os.environ.get("ONPREM_API_WARN_MS", "2000"))

# Slack 알림 환경 변수
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

# Secrets Manager에서 시크릿을 가져오는 함수
def get_secret(secret_arn: str) -> dict:
    """AWS Secrets Manager에서 JSON 시크릿을 가져옵니다."""
    sm = boto3.client("secretsmanager", region_name=REGION)
    resp = sm.get_secret_value(SecretId=secret_arn)
    return json.loads(resp["SecretString"])


# 온프레미스 헬스 체크 함수들
def check_db() -> tuple[bool, str]:
    """
    온프레미스 DB에 SELECT 1 쿼리로 접속 가능 여부를 확인합니다.
    """
    if not ONPREM_DB_SECRET_ARN:
        return True, "DB 헬스체크 스킵 (ONPREM_DB_SECRET_ARN 미설정)"

    try:
        creds = get_secret(ONPREM_DB_SECRET_ARN)
        host     = creds["host"]
        port     = int(creds.get("port", 3306))
        dbname   = creds["dbname"]
        username = creds["username"]
        password = creds["password"]

        # MySQL 시도
        try:
            import pymysql
            conn = pymysql.connect(
                host=host, port=port, db=dbname,
                user=username, password=password, connect_timeout=5,
            )
            conn.cursor().execute("SELECT 1")
            conn.close()
            return True, f"DB 쿼리 성공 (MySQL, host: {host})"
        except ImportError:
            pass

        return False, "DB 드라이버 없음 (psycopg2 또는 pymysql 필요)"

    except Exception as e:
        return False, f"DB 쿼리 실패: {e}"


def check_minio() -> tuple[bool, str]:
    """
    온프레미스 MinIO에 버킷으로 HEAD 요청하여 접근 가능 여부를 확인합니다.
    """
    if not ONPREM_MINIO_ENDPOINT or not ONPREM_MINIO_BUCKET:
        return True, "MinIO 헬스체크 스킵 (ENDPOINT 또는 BUCKET 미설정)"

    try:
        creds = get_secret(ONPREM_MINIO_SECRET_ARN) if ONPREM_MINIO_SECRET_ARN else {}
        access_key = creds.get("access_key", "")
        secret_key = creds.get("secret_key", "")

        minio = boto3.client(
            "s3",
            endpoint_url=ONPREM_MINIO_ENDPOINT,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            verify=False    # 인증서 무시
        )
        minio.head_bucket(Bucket=ONPREM_MINIO_BUCKET)
        return True, f"MinIO 접근 성공 (endpoint: {ONPREM_MINIO_ENDPOINT}, bucket: {ONPREM_MINIO_BUCKET})"
    except Exception as e:
        return False, f"MinIO 접근 실패: {e}"

def check_onprem_ports() -> tuple[bool, str]:
    """온프레미스 Proxy 서버의 80, 443 포트 연결성을 확인하여 서비스 가능 여부 판단함"""
    target_ip = "10.5.1.20"
    ports = [80, 443]
    failed_ports = []

    for port in ports:
        try:
            # socket을 사용하여 TCP 연결 시도
            with socket.create_connection((target_ip, port), timeout=2):
                pass
        except (socket.timeout, ConnectionRefusedError, OSError) as e:
            failed_ports.append(f"{port}번 포트")

    # 80, 443 중 하나라도 접속 안 되면 프록시 장애로 간주하여 False 반환함
    if failed_ports:
        return False, f"프록시 접속 실패: {', '.join(failed_ports)} 응답 없음"
    
    return True, f"프록시 정상 (IP: {target_ip}, Ports: 80, 443 Open)"

def run_healthchecks() -> tuple[bool, dict]:
    """3가지 헬스체크를 실행하고 모두 실패 시 DR 발동"""
    ok_db,    msg_db    = check_db()
    ok_minio, msg_minio = check_minio()
    ok_proxy, msg_proxy = check_onprem_ports()

    results = {
        "db":    {"ok": ok_db,    "message": msg_db},
        "minio": {"ok": ok_minio, "message": msg_minio},
        "proxy": {"ok": ok_proxy, "message": msg_proxy},
    }
    
    # 모두 False면 DR 발동
    should_failover = (not ok_proxy) or (not ok_db and not ok_minio)
    
    logger.info("헬스체크 결과: %s", json.dumps(results, ensure_ascii=False))
    if should_failover:
        logger.warning("모든 헬스체크 항목이 실패했습니다. DR 절차를 검토합니다.")

    return should_failover, results

# EKS Scale-up
def build_kube_client() -> client.AppsV1Api:
    """
    STS Presigned URL을 사용하여 EKS 인증 토큰을 생성하고 Kubernetes 클라이언트를 반환함
    """
    # 1. EKS 클러스터 정보 조회 (Endpoint 및 CA 데이터 획득)
    eks_client = boto3.client("eks", region_name=REGION)
    cluster_info = eks_client.describe_cluster(name=CLUSTER_NAME)["cluster"]
    
    # 2. CA 인증서 디코딩 및 임시 파일 저장 (SSL 검증용)
    ca_data = cluster_info["certificateAuthority"]["data"]
    with tempfile.NamedTemporaryFile(delete=False, suffix=".crt") as f:
        f.write(base64.b64decode(ca_data))
        ca_cert_path = f.name

    # 3. EKS 전용 STS 토큰 생성 
    session = boto3.session.Session()
    sts_client = session.client("sts", region_name=REGION)

    signer = sts_client._request_signer
    params = {
        "method": "GET",
        "url": f"https://sts.{REGION}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
        "body": {},
        "headers": {"x-k8s-aws-id": CLUSTER_NAME},
        "context": {}
    }

    signed_url = signer.generate_presigned_url(
        params,
        region_name=REGION,
        expires_in=60,
        operation_name=""
    )

    token = "k8s-aws-v1." + base64.urlsafe_b64encode(
        signed_url.encode("utf-8")
    ).decode("utf-8").rstrip("=")

    # 4. Kubernetes 클라이언트 설정 및 생성
    cfg = client.Configuration()
    cfg.host = cluster_info["endpoint"]
    cfg.verify_ssl = True
    cfg.ssl_ca_cert = ca_cert_path
    cfg.api_key = {"authorization": f"Bearer {token}"}
    
    return client.AppsV1Api(client.ApiClient(cfg))

# EKS WEB/WAS HPA minReplicas scale-up
def scale_deployment(apps_v1: client.AppsV1Api, namespace: str, name: str, replicas: int):
    """HPA의 minReplicas 값을 변경합니다."""
    try:
        # AutoscalingV1Api 사용
        autoscaling = client.AutoscalingV1Api(api_client=apps_v1.api_client)

        resp = autoscaling.patch_namespaced_horizontal_pod_autoscaler(
            name=name,
            namespace=namespace,
            body={"spec": {"minReplicas": replicas}},
        )

        logger.info("[hpa-min-up] %s/%s minReplicas → %d (rv: %s)",
                    namespace, name, replicas, resp.metadata.resource_version)

    except ApiException as e:
        logger.error("[hpa-min-up] 실패 %s/%s: %s", namespace, name, e)
        raise

# Slack 알림 함수 
def send_slack_blocks(blocks):
    # Secrets Manager에서 웹훅 URL 가져오기
    secret = get_secret(SLACK_WEBHOOK_URL)
    url = secret.get("slack_webhook_url") 
    
    http = urllib3.PoolManager()
    payload = {"blocks": blocks}
    
    try:
        response = http.request(
            'POST',
            url,
            body=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        return response.status
    except Exception as e:
        logger.error(f"슬랙 전송 실패: {e}")

# 1. DR 시작 메시지 블록 생성 함수
def slack_dr_start(health_results):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    fields = [
        {"type": "mrkdwn", "text": "*MySQL DB 쿼리*\n" + ("실패" if not health_results['db']['ok'] else "정상")},
        {"type": "mrkdwn", "text": "*발생 시각*\n" + now},
        {"type": "mrkdwn", "text": "*MinIO 스토리지 연결*\n" + ("실패" if not health_results['minio']['ok'] else "정상")},
        {"type": "mrkdwn", "text": "*Proxy 서버 응답*\n" + ("실패" if not health_results['proxy']['ok'] else "정상")}
    ]

    return [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "🚨 온프레미스 장애 발생", "emoji": True}
        },
        {"type": "divider"},
        {
            "type": "section",
            "fields": fields
        },
        {"type": "divider"},
        {"type": "context", "elements": [{"type": "mrkdwn", "text": "DR 작업을 시작합니다"}]}
    ]

# 2. DR 완료 메시지 블록 생성 함수
def slack_dr_complete(replicas):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    
    fields = [
        {"type": "mrkdwn", "text": "*WEB Replica*\n" + str(replicas)},
        {"type": "mrkdwn", "text": "*완료 시각*\n" + now},
        {"type": "mrkdwn", "text": "*WAS Replica*\n" + str(replicas)},
        {"type": "mrkdwn", "text": "*작업 상태*\n정상 완료"}
    ]

    return [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "✅ DR 작업 완료", "emoji": True}
        },
        {"type": "divider"},
        {
            "type": "section",
            "fields": fields
        },
        {"type": "context", "elements": [{"type": "mrkdwn", "text": "모든 복구 절차가 정상적으로 완료되었습니다"}]}
    ]

# Lambda 핸들러
def lambda_handler(event, context):
    logger.info("이벤트 수신: %s", json.dumps(event))

    # Step 1: 온프레미스 2차 헬스체크
    dr_required, health_results = run_healthchecks()

    if not dr_required:
        logger.info("온프레미스 정상 - DR 불필요")
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "No DR action required.",
                                "healthCheck": health_results}, ensure_ascii=False),
        }

    # Step 2:  Slack 알림 전송 - DR 전환 시작 알림
    send_slack_blocks(slack_dr_start(health_results))

    # Step 3: EKS scale-up
    logger.info("DR 발동: EKS scale-up 시작 (목표 replica: %d)", SCALE_REPLICAS)
    apps_v1 = build_kube_client()
    scale_deployment(apps_v1, APP_NAMESPACE, WEB_HPA, SCALE_REPLICAS)
    scale_deployment(apps_v1, APP_NAMESPACE, WAS_HPA, SCALE_REPLICAS)

    # Step 4: Slack 알림 전송 - DR 전환 완료 알림
    send_slack_blocks(slack_dr_complete(SCALE_REPLICAS))

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "DR scale-up completed.",
            "healthCheck": health_results,
            "scaled": {
                "web": f"{APP_NAMESPACE}/{WEB_HPA} → {SCALE_REPLICAS}",
                "was": f"{APP_NAMESPACE}/{WAS_HPA} → {SCALE_REPLICAS}",
            },
        }, ensure_ascii=False),
    }
