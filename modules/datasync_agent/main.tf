/*
############################################
# Remote State (network)
############################################
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "global/s3/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}

locals {
  vpc_id          = data.terraform_remote_state.network.outputs.team_vpc_id
  public_subnets  = data.terraform_remote_state.network.outputs.team_pubsn_ids
  private_subnets = data.terraform_remote_state.network.outputs.team_prisn_ids
}
*/
############################################
# Latest DataSync Agent AMI (SSM)
############################################
data "aws_ssm_parameter" "datasync_ami" {
  name = "/aws/service/datasync/ami"
}

data "aws_ami" "datasync_agent" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.datasync_ami.value]
  }
}

############################################
# Security Group (DataSync Agent)
############################################
resource "aws_security_group" "agent_sg" {
  name        = "${var.name}-sg"
  description = "Security group for DataSync Agent in our VPC"
  vpc_id      = var.team_vpc_id # 우리 VPC ID

  # 아웃바운드는 내부/외부 모두 통신 가능하도록 전체 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-sg" }
}

# 1. 온프레미스 대역 ICMP 허용
resource "aws_security_group_rule" "icmp_onprem" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["10.5.0.0/16"]
  security_group_id = aws_security_group.agent_sg.id
}

# 2. 우리 VPC 내부 대역(Private 포함) 전체 통신 허용
# 에이전트가 프라이빗 리소스에 접근하기 위해 필요합니다.
resource "aws_security_group_rule" "internal_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["20.0.0.0/16"] # 우리 VPC 대역
  security_group_id = aws_security_group.agent_sg.id
}

# 3. 에이전트 활성화용 HTTP 80
resource "aws_security_group_rule" "http_activation" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.agent_sg.id
}

############################################
# IAM Role & Instance Profile
############################################
resource "aws_iam_role" "datasync_agent" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "datasync" {
  role       = aws_iam_role.datasync_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AWSDataSyncFullAccess"
}

resource "aws_iam_instance_profile" "datasync_agent" {
  name = "${var.name}-profile"
  role = aws_iam_role.datasync_agent.name
}

############################################
# EC2 DataSync Agent (Public/Private 통신 가능 환경)
############################################
resource "aws_instance" "datasync_agent" {
  ami           = data.aws_ami.datasync_agent.id
  instance_type = var.instance_type

  # 에이전트는 퍼블릭 서브넷에 생성하여 활성화 경로 확보
  subnet_id                   = var.team_pubsn_ids[0]
  associate_public_ip_address = true 

  vpc_security_group_ids = [aws_security_group.agent_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.datasync_agent.name

  tags = {
    Name = var.name
  }

  lifecycle {
    ignore_changes = [ami, associate_public_ip_address]
  }
}