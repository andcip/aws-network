terraform {
  experiments = [module_variable_optional_attrs]
}

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
  route_table_id = aws_route_table.public[count.index].id
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


module "vpce" {
  source = "./vpce"
  count = length(var.vpc_endpoints) > 0 ? 1 : 0
  vpc = {id: aws_vpc.main.id, cidr: aws_vpc.main.cidr_block, private_subnets_ids: aws_subnet.private.*.id, private_route_table_ids: aws_route_table.private.*.id}
  vpc_endpoints = var.vpc_endpoints
}

module "bastion" {
  source = "./bastion"
  count = var.bastion.enabled ? 1 : 0
  acm_key_name = var.bastion.certificate_name
  acm_key_file = var.bastion.certificate_key
  vpc = {id: aws_vpc.main.id, public_subnet_id: aws_subnet.public[0].id}

}


resource "aws_ssm_parameter" "private_subnet_ids" {
  count       = var.subnets.private.count
  name        = "/infrastructure/vpc/subnets/private/${count.index}/id"
  description = "Export the private subnet ${count.index} id"
  type        = "String"
  value       = aws_subnet.private[count.index].id
}

resource "aws_ssm_parameter" "vpc" {
  name        = "/infrastructure/vpc/id"
  description = "Export vpc id"
  type        = "String"
  value       = aws_vpc.main.id
}
