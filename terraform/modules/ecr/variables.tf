variable "project_name" {
  description = "Project name used for ECR repository naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "repositories" {
  description = "Names of ECR repositories to create"
  type        = set(string)

  validation {
    condition     = length(var.repositories) > 0
    error_message = "At least one ECR repository must be specified."
  }
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
