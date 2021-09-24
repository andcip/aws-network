variable "cidr_block" {
  type = string
}

variable "tg_routes" {
  type = list(string)
  default = []
}

variable "common_tags" {
  type = map(string)
}

variable "project_name" {
  type = string
}

variable "subnets" {
  type = object({
    private: object({
      count: number,
      cidr: list(string)
    }),
    public: object({
      count: number,
      cidr: list(string)
    })
  })
  default = {private: {count:2, cidr: []}, public: {count:2, cidr: []}}
  validation {
    condition = var.subnets.private.cidr == [] || length(var.subnets.private.cidr) == var.subnets.private.count
    error_message = "Private Subnets CIDR size must be equal to private subnets count."
  }
  validation {
    condition = var.subnets.public.cidr == [] || length(var.subnets.public.cidr) == var.subnets.public.count
    error_message = "Public Subnets CIDR size must be equal to public subnets count."
  }
}
