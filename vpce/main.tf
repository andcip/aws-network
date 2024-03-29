data "aws_region" "current" {}

resource "aws_security_group" "vpc_endpoint_security_group" {
  count = length(var.vpc_endpoints) > 0  && contains(var.vpc_endpoints, "s3") || contains(var.vpc_endpoints, "dynamodb") ? 1 : 0

  name        = "VPCEndpointSecurityGroup"
  description = "VPC Endpoint SecurityGroup"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "VPCEndpointSecurityGroup" }

}

locals {
  isGateway = [ for endpoint in var.vpc_endpoints: contains(["s3", "dynamodb"], endpoint )]
}

resource "aws_vpc_endpoint" "vpc_endpoints" {
  count        = length(var.vpc_endpoints)
  service_name = "com.amazonaws.${data.aws_region.current.name}.${var.vpc_endpoints[count.index]}"
  vpc_id       = var.vpc.id

  vpc_endpoint_type = local.isGateway[count.index] ? "Gateway" : "Interface"
  route_table_ids   = local.isGateway[count.index] ? var.vpc.private_route_table_ids : null

  subnet_ids = local.isGateway[count.index]  ? null : var.vpc.private_subnets_ids

  private_dns_enabled = local.isGateway[count.index]  ? null : true

  security_group_ids = local.isGateway[count.index]  ? null : [aws_security_group.vpc_endpoint_security_group[0].id]

  tags = { "Name" : "vpce-${var.vpc_endpoints[count.index]}" }

}
