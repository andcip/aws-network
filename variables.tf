variable "cidr_block" {
  type        = string
  description = "The CIDR block to use fot the VPC."
}

variable "tg_routes" {
  type        = list(string)
  default     = []
  description = "List of subnets to route to the transit gateway."
}

variable "project_name" {
  type        = string
  description = "The project name, must not be empty"
}

variable "vpc_flow_log_enabled" {
  type        = bool
  default     = false
  description = "Enable the VPC flow logs, default disabled"
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

  description = "Utility object to specify private and public subnets. You can choose the number and the cidr of everyone. Default goes to 2 private and 2 public and the relative cidrs are calculated based on vpc"

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
  type        = list(string)
  default     = []
  description = "List of vpc endpoint to enable."

  validation {
    condition     = alltrue([
    for vpce in var.vpc_endpoints : contains(["s3", "sns", "execute-api", "dynamodb", "ecr.dkr", "ecr.api", "rds"], vpce)
    ])
    error_message = "Invalid VPC Endpoint service, allowed values are s3, sns, execute-api, dynamodb, ecr.api, ecr.dkr, rds."
  }
}

variable "bastion" {
  type        = object({
    enabled : bool,
    certificate_name : string,
    certificate_key : string
  })
  default     = { enabled : false, certificate_name : null, certificate_key : null }
  description = "Choose if enable bastion host, with the given ssh certificate"

  validation {
    condition = var.bastion.enabled ? var.bastion.certificate_name != null && var.bastion.certificate_key != null : true

    error_message = "If bastion is enabled, certificate_name and certificate_key must not be null."
  }
}
