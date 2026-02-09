
# data "terraform_remote_state" "network_module" {
#   backend = "s3"
#   config = {
#     bucket  = "team-tfstate-bucket"
#     key     = "module/network/terraform.tfstate"
#     region  = "ap-northeast-2"
#     profile = "process"
#   }
# }

# # 로컬 변수에 할당
# locals {
#   team_vpc_id     = data.terraform_remote_state.network_module.outputs.team_vpc_id
#   team_subnet_ids = data.terraform_remote_state.network_module.outputs.team_prisn_ids
# }


# 1. 기존 VPC 정보 가져오기
data "aws_vpc" "selected" {
  id = var.team_vpc_id
}

# 2. 보안 그룹 설정
resource "aws_security_group" "aurora_sg" {
  name        = "team-aurora-sg"
  description = "Security group for Aurora and Interface Endpoint"
  vpc_id      = var.team_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow MySQL traffic from internal VPC"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.5.4.0/24"]
    description = "Allow Replication traffic from On-premise"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "team-aurora-sg" }
}

# 3. 서브넷 그룹
resource "aws_db_subnet_group" "aurora_sng" {
  name       = "team-aurora-sng"
  subnet_ids = var.team_prisn_ids
}

# 4. Aurora MySQL 클러스터
resource "aws_rds_cluster" "aurora" {

  cluster_identifier = "team-aurora-cluster"
  engine             = "aurora-mysql"
  engine_version     = "8.0"
  master_username    = var.db_username
  master_password    = var.db_password

  db_subnet_group_name            = aws_db_subnet_group.aurora_sng.name
  vpc_security_group_ids          = [aws_security_group.aurora_sg.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg.name

  skip_final_snapshot = true
  apply_immediately   = true
}

# 5. 클러스터 인스턴스
resource "aws_rds_cluster_instance" "aurora_instance" {
  count                = var.instance_count
  cluster_identifier   = aws_rds_cluster.aurora.id
  identifier           = "team-aurora-instance-${count.index + 1}"
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.aurora_sng.name
}


# 6. 파라미터 그룹
resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  name   = "team-aurora-pg"
  family = "aurora-mysql8.0"

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "gtid-mode"
    value        = "on"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "enforce_gtid_consistency"
    value        = "on"
    apply_method = "pending-reboot"
  }
}
