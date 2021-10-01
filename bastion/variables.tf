variable "vpc" {
  type = object({
    id: string,
    public_subnet_id: string
  })
}

variable "acm_key_name" {
  type = string
}

variable "acm_key_file" {
  type = string
  default = null
}
