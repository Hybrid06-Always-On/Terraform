# 기존 VPC 정보 가져오기
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# VPC 내의 서브넷 자동 탐색
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}


resource "aws_security_group" "aurora_sg" {
  name        = "dr-final-db-sg"
  description = "Security group for Aurora and Interface Endpoint"
  vpc_id      = var.vpc_id


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow MySQL traffic from internal VPC (Backend)"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.5.4.0/24"]
    description = "Allow Replication traffic from On-premise DB via VPN"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dr-final-db-sg"
  }
}

# Aurora MySQL 클러스터
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "dr-final-aurora-cluster"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.04.0"
  master_username    = var.db_username
  master_password    = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.aurora_sng.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg.name

  skip_final_snapshot = true
  apply_immediately   = true
}

# 클러스터 인스턴스
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier          = "dr-final-instance-1"
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = "db.t3.medium"
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  publicly_accessible = false
}

# 인터페이스 엔드포인트
resource "aws_vpc_endpoint" "rds_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.rds"
  vpc_endpoint_type = "Interface"

  # 필터링된 프라이빗 서브넷 ID들을 모두 넣음
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.aurora_sg.id]
  private_dns_enabled = true

  tags = { Name = "dr-aurora-interface-endpoint-prod" }
}
# 서브넷 그룹
resource "aws_db_subnet_group" "aurora_sng" {
  name       = "dr-final-aurora-sng"
  subnet_ids = data.aws_subnets.private.ids
}

# 파라미터 그룹 (복제를 위해 binlog 필수)
resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  name   = "dr-final-aurora-pg"
  family = "aurora-mysql8.0"

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  # GTID 활성화
  parameter {
    name  = "gtid_mode"
    value = "ON"
  }

  parameter {
    name  = "enforce_gtid_consistency"
    value = "ON"
  }
}
