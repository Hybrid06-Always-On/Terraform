# 1. VPC 생성 - 10.5.0.0/16
resource "aws_vpc" "team_VPC" {
  cidr_block           = var.team_vpc_cidr
  enable_dns_hostnames = true # DNS 호스트이름 활성화

  tags = {
    Name = "team_VPC"
  }
}

# 2. IGW 생성 및 VPC 연결
resource "aws_internet_gateway" "team_IGW" {
  vpc_id = aws_vpc.team_VPC.id

  tags = {
    Name = "team_IGW"
  }
}

# 3. Public Subnet 3개 생성
# * cidr block 정보
# - 10.5.5.0/24
# - 10.5.6.0/24
# - 10.5.7.0/24

resource "aws_subnet" "team_PubSN" {
  count = length(var.team_public_subnets)

  vpc_id                  = aws_vpc.team_VPC.id                  # VPC 지정
  availability_zone       = var.team_azs[count.index]            # 가용 영역
  cidr_block              = var.team_public_subnets[count.index] # CIDR 블록
  map_public_ip_on_launch = true                                 # 공인 IP 자동 할당 설정

  tags = {
    Name                                        = "team-PubSN-${count.index + 1}" # index가 0부터 시작하므로 +1을 필요
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"                        # EKS 클러스터용 태그
    "kubernetes.io/role/elb"                    = "1"                             # ELB용 태그
  }
}

# 4. Public Route Table 생성
# * 라우팅 테이블 정보
# - teamPubRT1, teamPubRT2, teamPubRT3
# - IGW 연결 & Public Subnet 3개와 연결

resource "aws_route_table" "team_PubSN-RT" {
  count  = length(var.team_public_subnets) # Public Subnet 개수만큼 생성
  vpc_id = aws_vpc.team_VPC.id             # VPC 지정

  # 라우팅 테이블 설정
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.team_IGW.id
  }

  tags = {
    Name = "team_PubSN-RT${count.index + 1}"
  }
}

# Public Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "team_PubSN-RT-assoc" {
  count = length(var.team_public_subnets)

  subnet_id      = aws_subnet.team_PubSN[count.index].id
  route_table_id = aws_route_table.team_PubSN-RT[count.index].id
}

# 5. NAT Gateway 생성
# - Elastic IP 생성
# - NAT Gateway 생성

resource "aws_eip" "team_EIP" {
  count  = length(var.team_public_subnets) # Public Subnet 개수만큼 생성
  domain = "vpc"                           # 탄력적 IP를 VPC 내에서 사용

  tags = {
    Name = "team_EIP-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "team_NAT-GW" {
  count         = length(var.team_public_subnets)       # Public Subnet 개수만큼 생성
  allocation_id = aws_eip.team_EIP[count.index].id      # EIP 할당 
  subnet_id     = aws_subnet.team_PubSN[count.index].id # Public Subnet 연결

  tags = {
    Name = "team_NAT-GW-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.team_IGW] # IGW 생성 후 NAT Gateway 생성되도록 명시
}

# 6. Private Subnet 3개 생성
# * cidr block 정보
# - 10.5.8.0/24
# - 10.6.9.0/24
# - 10.7.1-.0/24

resource "aws_subnet" "team_PriSN" {
  count = length(var.team_private_subnets) # Private Subnet 개수만큼 생성

  vpc_id            = aws_vpc.team_VPC.id                   # VPC 지정
  availability_zone = var.team_azs[count.index]             # 가용 영역
  cidr_block        = var.team_private_subnets[count.index] # CIDR 블록

  tags = {
    Name                                        = "team_PriSN-${count.index + 1}" # index가 0부터 시작하므로 +1을 필요
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"                        # EKS 클러스터용 태그
    "kubernetes.io/role/internal-elb"           = "1"                             # ELB용 태그
  }
}

# 7. Private Route Table 생성
# * 라우팅 테이블 정보
# - team_PriRT1, team_PriRT2, team_PriRT3
# - NAT Gateway & Private Subnet 연결

resource "aws_route_table" "team_PriSN-RT" {
  count  = length(var.team_private_subnets) # Private Subnet 개수만큼 생성
  vpc_id = aws_vpc.team_VPC.id              # VPC 지정

  # 라우팅 테이블 설정
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.team_NAT-GW[count.index].id
  }

  tags = {
    Name = "team_PriSN-RT${count.index + 1}"
  }
}

# Private Subnet과 라우팅 테이블 연결
resource "aws_route_table_association" "team_PriSN-RT-assoc" {
  count = length(var.team_private_subnets)

  subnet_id      = aws_subnet.team_PriSN[count.index].id
  route_table_id = aws_route_table.team_PriSN-RT[count.index].id
}
