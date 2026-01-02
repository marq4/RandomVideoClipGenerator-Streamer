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

variable "scripts-bucket-name" {
  type        = string
  description = "Name of the S3 bucket that hosts core Python, and PowerShell scripts."
  default     = "rvcgs-marq-scripts-30122025"
}

variable "playlist-bucket-name" {
  type        = string
  description = "Name of the S3 bucket where Lambda writes clips.xspf to."
  default     = "rvcgs-marq-xspf-playlist-31122025"
}

variable "main-dot-com-apex-url" {
  type        = string
  description = "Apex.com domain URL"
  default     = "randomvideoclipgenerator.com"
}

variable "lambda-runtime" {
  type        = string
  description = "All 3 functions share the same runtime"
  default     = "python3.10"
}
