variable "aws_region" {
  description = "AWS region where the Terraform state bucket will be created"
  type        = string
}

variable "project_name" {
  description = "Project name used for state bucket naming"
  type        = string
}

variable "tags" {
  description = "Common tags applied to the state bucket"
  type        = map(string)
  default     = {}
}
