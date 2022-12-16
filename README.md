# Networking

## AWS Networking general module

--------------

This module deploy a complete VPC, with Endpoints, Routing tables and a Bastion Host based on input variables


### Example of invocation

```
## If subnet are not specified, 4 subnets ( 2 public and 2 private ) are created automatically from the vpc cidr.
cidr_block = "10.0.0.0/24"

project_name = "Test"

vpc_endpoints = ["s3", "ecr.dkr", "ecr.api"]

bastion = {
  enabled : true,
  certificate_name : "test-certificate",
  certificate_key : "${get_terragrunt_dir()}/../investor.pub"
}

```

------------

# Variable Documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./bastion | n/a |
| <a name="module_vpce"></a> [vpce](#module\_vpce) | ./vpce | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.vpc_flow_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.tg_vpc_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.vpc_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_log_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ng](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_ssm_parameter.private_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.az](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ec2_transit_gateway.transit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion"></a> [bastion](#input\_bastion) | Choose if enable bastion host, with the given ssh certificate | <pre>object({<br>    enabled : bool,<br>    certificate_name : string,<br>    certificate_key : string<br>  })</pre> | <pre>{<br>  "certificate_key": null,<br>  "certificate_name": null,<br>  "enabled": false<br>}</pre> | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block to use fot the VPC. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The project name, must not be empty | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Utility object to specify private and public subnets. You can choose the number and the cidr of everyone. Default goes to 2 private and 2 public and the relative cidrs are calculated based on vpc | <pre>object({<br>    private : object({<br>      count : number,<br>      cidr : list(string)<br>    }),<br>    public : object({<br>      count : number,<br>      cidr : list(string)<br>    })<br>  })</pre> | <pre>{<br>  "private": {<br>    "cidr": [],<br>    "count": 2<br>  },<br>  "public": {<br>    "cidr": [],<br>    "count": 2<br>  }<br>}</pre> | no |
| <a name="input_tg_routes"></a> [tg\_routes](#input\_tg\_routes) | List of subnets to route to the transit gateway. | `list(string)` | `[]` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | List of vpc endpoint to enable. | `list(string)` | `[]` | no |
| <a name="input_vpc_flow_log_enabled"></a> [vpc\_flow\_log\_enabled](#input\_vpc\_flow\_log\_enabled) | Enable the VPC flow logs, default disabled | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_transit_routes"></a> [transit\_routes](#output\_transit\_routes) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |
<!-- END_TF_DOCS -->
