variable "cidr_block" {
  type = string
}

variable "tg_routes" {
  type    = list(string)
  default = []
}

variable "project_name" {
  type = string
}

variable "subnets" {
  type = object({
    private : object({
      count : number,
      cidr : list(string)
    }),
    public : object({
      count : number,
      cidr : list(string)
    })
  })

  default = { private : { count : 2, cidr : [] }, public : { count : 2, cidr : [] } }

  validation {
    condition     = length(var.subnets.private.cidr) == 0 || length(var.subnets.private.cidr) == var.subnets.private.count
    error_message = "Private Subnets CIDR size must be equal to private subnets count."
  }
  validation {
    condition     = length(var.subnets.public.cidr) == 0 || length(var.subnets.public.cidr) == var.subnets.public.count
    error_message = "Public Subnets CIDR size must be equal to public subnets count."
  }
}

variable "vpc_endpoints" {
  type    = list(string)
  default = []
  validation {
    condition     = alltrue([
    for vpce in var.vpc_endpoints : contains(["s3", "sns", "execute-api", "dynamodb", "ecr.dkr", "ecr.api"], vpce)
    ])
    error_message = "Invalid VPC Endpoint service, allowed values are s3, sns, execute-api, dynamodb, ecr.api, ecr.dkr ."
  }
}

variable "bastion" {
  type = object({
    enabled : bool,
    certificate_name : string,
    certificate_key : string
  })
}
