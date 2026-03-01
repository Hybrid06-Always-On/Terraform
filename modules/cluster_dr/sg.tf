# Lambda DR 함수 전용 보안 그룹
resource "aws_security_group" "lambda_dr_sg" {
  name        = "lambda-dr-sg"
  description = "Security group for DR Lambda function"
  vpc_id      = var.team_vpc_id

  # 아웃바운드: HTTPS (EKS API 서버, Secrets Manager, 온프레미스 헬스체크)
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: HTTP (온프레미스 API/MinIO 헬스체크용)
  egress {
    description = "HTTP outbound for on-prem health check"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: MySQL (온프레미스 DB 헬스체크용)
  egress {
    description = "MySQL outbound for on-prem DB health check"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: MinIO (온프레미스 MinIO 헬스체크용)
  egress {
    description = "MinIO outbound for on-prem health check"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "lambda-dr-sg"
    Project = "team"
    Purpose = "DR Lambda egress"
  }
}
