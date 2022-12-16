data "aws_availability_zones" "az" {}

data "aws_ec2_transit_gateway" "transit" {
  count = length(var.tg_routes) > 0 ? 1 : 0
}

locals {
  total_subnets_count = var.subnets.private.count + var.subnets.public.count
  subnets             = [
  for i in range(local.total_subnets_count) :
  cidrsubnet(var.cidr_block, ceil(log(local.total_subnets_count, 2 )), i )
  ]
  private_subnets     = [for i in range(var.subnets.private.count) : local.subnets[i]]
  public_subnets      = [for i in range(var.subnets.private.count, local.total_subnets_count) : local.subnets[i]]

}

## VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { "Name" : var.project_name }
}


## Public Subnets
resource "aws_subnet" "public" {
  count                   = var.subnets.public.count
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = length(var.subnets.public.cidr) > 0 ? var.subnets.public.cidr[count.index] : local.public_subnets[count.index]

  tags = {
    "Name" = "public-subnet-${count.index}"
    "AZ"   = data.aws_availability_zones.az.names[count.index]
    "Type" = "Public"
  }
}

## Private Subnets
resource "aws_subnet" "private" {
  count                   = var.subnets.private.count
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = length(var.subnets.public.cidr) > 0 ? var.subnets.private.cidr[count.index] : local.private_subnets[count.index]

  tags = {
    "Name" = "private-subnet-${count.index}"
    "AZ"   = data.aws_availability_zones.az.names[count.index]
    "Type" = "Private"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "igw" {
  count  = var.subnets.public.count > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id
}

## Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  count = var.subnets.public.count
  vpc   = true
  tags  = { Name = "natgw-eip-${count.index}" }
}

## NAT Gateway
resource "aws_nat_gateway" "ng" {
  count         = var.subnets.public.count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.igw[0]]
  tags          = { Name = "natgw-${count.index}" }
}

## Private Route Table
resource "aws_route_table" "private" {
  count  = var.subnets.private.count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng[count.index % length(aws_nat_gateway.ng)].id
  }

  # VPN
  dynamic "route" {
    for_each = var.tg_routes
    content {
      cidr_block         = route.value
      transit_gateway_id = data.aws_ec2_transit_gateway.transit[0].id
    }
  }

  tags = { Name = "private-rt-${count.index}" }
}

## Public Route Table
resource "aws_route_table" "public" {
  count  = var.subnets.public.count > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[count.index].id
  }
  tags   = { Name = "public-rt" }
}


resource "aws_route_table_association" "public" {
  count          = var.subnets.public.count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count          = var.subnets.private.count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

## Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "tg_vpc_attachment" {
  count              = length(var.tg_routes) > 0 ? 1 : 0
  subnet_ids         = aws_subnet.private.*.id
  transit_gateway_id = data.aws_ec2_transit_gateway.transit[0].id
  vpc_id             = aws_vpc.main.id
}

resource "aws_flow_log" "vpc_flow_log" {
  count           = var.vpc_flow_log_enabled ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_log_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  count             = var.vpc_flow_log_enabled ? 1 : 0
  name              = "vpc_flow_log"
  retention_in_days = 180
}

resource "aws_iam_role" "flow_log_role" {
  count = var.vpc_flow_log_enabled ? 1 : 0
  name  = "${var.project_name}_vpc_flow_log_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flow_log_policy" {
  count = var.vpc_flow_log_enabled ? 1 : 0
  name  = "${var.project_name}_flow_log_policy"
  role  = aws_iam_role.flow_log_role[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


module "vpce" {
  source        = "./vpce"
  count         = length(var.vpc_endpoints) > 0 ? 1 : 0
  vpc           = {
    id : aws_vpc.main.id,
    cidr : aws_vpc.main.cidr_block,
    private_subnets_ids : aws_subnet.private.*.id,
    private_route_table_ids : aws_route_table.private.*.id
  }
  vpc_endpoints = var.vpc_endpoints
}

module "bastion" {
  source       = "./bastion"
  count        = var.bastion.enabled ? 1 : 0
  acm_key_name = var.bastion.certificate_name
  acm_key_file = var.bastion.certificate_key
  vpc          = { id : aws_vpc.main.id, public_subnet_id : aws_subnet.public[0].id }

}
