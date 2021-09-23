variable "cidr_block" {
  type = string
}

variable "tg_routes" {
  type = list(string)
  default = []
}

variable "public_subnets_count" {
  type = number
  default = 2
}

variable "private_subnets_count" {
  type = number
  default = 2
}

variable "common_tags" {
  type = map(string)
}
