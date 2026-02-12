########################################
# S3 Gateway Endpoint (Private DR Path)
########################################

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.team_vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.team_prisn_rtb_id
  tags            = var.tags
}