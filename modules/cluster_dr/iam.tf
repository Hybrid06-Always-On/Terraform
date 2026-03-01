### Lambda 실행 Role 생성 및 권한 부여 ###
# [참고 문헌] https://docs.aws.amazon.com/ko_kr/lambda/latest/dg/lambda-intro-execution-role.html

# Lambda 실행 Role 생성
resource "aws_iam_role" "lambda_dr_role" {
  name = "lambda-dr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "team"
  }
}

# CloudWatch Logs 접근 권한 부여 -> Lambda 함수 실행 로그를 CloudWatch Logs에 기록
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC 실행 권한 부여 -> Lambda가 VPC 내 ENI 생성 가능
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_dr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# EKS 외부 접근 권한 부여
resource "aws_iam_role_policy" "lambda_eks_management" {
  name = "lambda-eks-management-policy"
  role = aws_iam_role.lambda_dr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:UpdateNodegroupConfig",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS 내부 접근 권한 부여-> EKS API 호출 권한
resource "aws_eks_access_entry" "lambda_dr" {
  cluster_name  = var.team_cluster_name
  principal_arn = aws_iam_role.lambda_dr_role.arn
  type          = "STANDARD"

  # depends_on = [module.eks]
}

# EKS 권한 정책 연결
# - AmazonEKSEditPolicy: Deployment patch 가능, 클러스터 설정 변경 불가
# - namespaces: Lambda가 접근할 네임스페이스만 허용 
resource "aws_eks_access_policy_association" "lambda_eks_edit" {
  cluster_name  = var.team_cluster_name
  principal_arn = aws_iam_role.lambda_dr_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.app_namespace]
  }

  depends_on = [aws_eks_access_entry.lambda_dr]
}

# Secrets Manager 접근 권한 부여 (온프레미스 DB / MinIO 자격증명)
resource "aws_iam_role_policy" "lambda_secrets_policy" {
  name = "lambda-dr-secrets-policy"
  role = aws_iam_role.lambda_dr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          var.onprem_db_secret_arn,
          var.onprem_minio_secret_arn,
          var.slack_webhook_url_arn
        ]
      }
    ]
  })
}


