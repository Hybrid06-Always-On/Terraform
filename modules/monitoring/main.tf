data "terraform_remote_state" "eks_cluster_module" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "global/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}
data "terraform_remote_state" "auroradb_module" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "global/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}
# 로컬 변수에 할당
locals {
  cluster_name       = data.terraform_remote_state.eks_cluster_module.outputs.cluster_name
  cluster_identifier = "https://D045E29799B89F8562253916601DE546.yl4.ap-northeast-2.eks.amazonaws.com"
  vpn_connection_id  = "no-vpn-id"
  cloudfront_id      = "no-cf-id"
}

# 1. 알림 통로 (이건 지금 바로 생성 가능)
resource "aws_sns_topic" "dr_alarms" {
  name = var.sns_topic_name
}

# 2. RDS 복제 지연 알람 (Aurora 완성되었으니 바로 작동)
resource "aws_cloudwatch_metric_alarm" "replica_lag" {
  alarm_name          = "DR-RDS-ReplicaLag-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RDSReplicationLag"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "300"
  alarm_actions       = [aws_sns_topic.dr_alarms.arn]

  dimensions = {
    DBClusterIdentifier = local.cluster_identifier
  }
}

# 3. VPN 알람 (vpn_connection_id가 있을 때만 생성)
resource "aws_cloudwatch_metric_alarm" "vpn_status" {
  count               = var.vpn_connection_id != null ? 1 : 0
  alarm_name          = "DR-VPN-Tunnel-Down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TunnelState"
  namespace           = "AWS/VPN"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.dr_alarms.arn]

  dimensions = {
    VpnConnectionId = var.vpn_connection_id
  }
}

# 4. 대시보드 (미완성 리소스는 지표가 안 나올 뿐 대시보드는 생성됨)
resource "aws_cloudwatch_dashboard" "dr_main" {
  dashboard_name = "DR-Service-Status"
  dashboard_body = jsonencode({
    widgets = [
      # 1. DB 복제 지연 (가장 중요)
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6,
        properties = {
          metrics = [["AWS/RDS", "RDSReplicationLag", "DBClusterIdentifier", local.cluster_identifier]],
          title   = "DB 복제 지연 (초)",
          region  = "ap-northeast-2"
        }
      },
      # 2. VPN 터널 상태 (연결 통로)
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6,
        properties = {
          # vpn_id가 없을 때를 대비해 변수 처리
          metrics = [["AWS/VPN", "TunnelState", "VpnConnectionId", local.vpn_connection_id]],
          title   = "VPN 터널 상태 (1:UP, 0:DOWN)",
          region  = "ap-northeast-2",
          period  = 60,
          stat    = "Minimum"
        }
      },
      # 3. EKS Pod 상태 (앱 생존 여부)
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6,
        properties = {
          metrics = [["AWS/EKS", "pod_ready_status", "ClusterName", local.cluster_name]],
          title   = "EKS Pod Ready 상태",
          region  = "ap-northeast-2"
        }
      },
      # 4. RDS CPU 사용률 (부하 확인)
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6,
        properties = {
          metrics = [["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", local.cluster_identifier]],
          title   = "RDS Cluster CPU 사용률 (%)",
          region  = "ap-northeast-2"
        }
      },
      # 5. CloudFront 에러율 (최종 사용자 경험)
      {
        type = "metric", x = 0, y = 12, width = 24, height = 6, # 가로로 길게 배치
        properties = {
          metrics = [["AWS/CloudFront", "TotalErrorRate", "Region", "Global", "DistributionId", local.cloudfront_id]],
          title   = "CloudFront 전체 에러율 (%)",
          region  = "us-east-1" # CloudFront 지표는 항상 us-east-1에 있음
        }
      }
    ]
  })
}
