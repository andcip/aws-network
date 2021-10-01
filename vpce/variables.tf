variable "vpc_endpoints" {
  type    = list(string)
  default = []
  validation {
    condition     = contains(var.vpc_endpoints, "s3") || contains(var.vpc_endpoints, "sns") || contains(var.vpc_endpoints, "execute-api") || contains(var.vpc_endpoints, "dynamodb") || contains(var.vpc_endpoints, "rds")

    error_message = "Invalid VPC Endpoint service, allowed values are s3, sns, execute-api, dynamodb, rds."
  }
}

variable "vpc" {
  type = object({
    id: string,
    cidr: string
    private_subnets_ids: list(string),
    private_route_table_ids: list(string)
  })
}
