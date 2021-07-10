variable "stack_name" {
  type        = string
  description = "Name to be applied to resources across the stack."
}

variable "aws_iam_username" {
  type        = string
  description = "Username of your IAM user. Necessary to obtain access to `kubectl`."
}

variable "base_cidr_block" {
  type        = string
  description = "CIDR range for the requested network."
}
