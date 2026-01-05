locals {
  # Load names of things (single source of truth):
  config = yamldecode(file("${path.module}/../config.yml"))

  # For all resources:
  common_tags = {
    ManagedBy = "Terraform"
    Project   = local.config.project_name
  }
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


variable "main-dot-com-apex-url" {
  type        = string
  description = "Apex.com domain URL."
  default     = "randomvideoclipgenerator.com"
}

variable "lambda-runtime" {
  type        = string
  description = "All functions share the same runtime."
  default     = "python3.10"
}
