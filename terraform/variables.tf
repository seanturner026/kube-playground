variable "stack_name" {
  type        = string
  description = "Name to be applied to resources across the stack."
}

variable "base_cidr_block" {
  type        = string
  description = "CIDR range for the requested network."
}
