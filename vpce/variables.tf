variable "vpc_endpoints" {
  type    = list(string)
  default = []
}

variable "vpc" {
  type = object({
    id: string,
    cidr: string
    private_subnets_ids: list(string),
    private_route_table_ids: list(string)
  })
}
