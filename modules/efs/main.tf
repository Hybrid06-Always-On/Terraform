/*
########################################
# Remote State (기존 설정 유지)
########################################

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "global/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}

data "terraform_remote_state" "datasync_agent" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "module/datasync_agent/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}

locals {
  
  vpc_id               = data.terraform_remote_state.network.outputs.team_vpc_id
  private_subnets      = data.terraform_remote_state.network.outputs.team_prisn_ids

  datasync_agent_sg_id = data.terraform_remote_state.datasync_agent.outputs.security_group_id
}
*/
########################################
# EFS File System (새로 생성)
########################################
resource "aws_efs_file_system" "this" {
  encrypted        = true
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  lifecycle_policy {
    transition_to_ia = var.efs_transition_to_ia
  }

  tags = {
    Name = var.efs_name
  }
}

########################################
# [핵심] EFS Access Point 
########################################
resource "aws_efs_access_point" "video_data" {
  file_system_id = aws_efs_file_system.this.id

  root_directory {
    path = "/video_data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name = "efs-video-access-point"
  }
}

########################################
# Security Group (오타 수정 반영)
########################################
resource "aws_security_group" "efs_sg" {
  name   = "team-efs-sg"
  #vpc_id = local.vpc_id
  vpc_id = var.team_vpc_id

  # 온프레미스 대역 (10.5.0.0/16)
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.5.0.0/16"]
    description = "NFS from On-prem Bastion"
  }

  # VPC 내부 통신 대역 (20.0.0.0/16)
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["20.0.0.0/16"]
    description = "NFS from our VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "team-efs-sg"
  }
}
########################################
# Mount Targets
########################################
resource "aws_efs_mount_target" "this" {
  # locals 대신 변수(variable) 사용
  for_each        = toset(var.team_prisn_ids) 
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

