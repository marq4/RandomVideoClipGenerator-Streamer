locals {
  # For all resources:
  common_tags = {
    ManagedBy = "Terraform"
    Project   = var.project
  }
}

variable "project" {
  type        = string
  description = "Project name for tags."
  default     = "RVCGS/serverless"
}

variable "ohio-code" {
  type        = string
  description = "Code for Ohio Region."
  default     = "us-east-2"
}

variable "north-virginia-code" {
  type        = string
  description = "Code for North Virginia Region."
  default     = "us-east-1"
}

variable "backend-bucket-name" {
  type        = string
  description = "Name of the S3 bucket used to store remote state."
  default     = "rvcgs-marq-remote-state-backend-30122025"
}
