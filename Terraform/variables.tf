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

variable "upload-bucket-name" {
  type        = string
  description = "Name of the S3 bucket where list_videos.txt is temporarily uploaded to."
  default     = "rvcgs-marq-list-videos-upload-05012026"
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

variable "core-function-name" {
  type        = string
  description = "Name of the core Lambda function."
  default     = "rvcgs-core"
}

variable "list-function-name" {
  type        = string
  description = "Name of the Lambda function that sends suggested YouTube music video list."
  default     = "rvcgs-send-suggestions-list"
}

variable "cleanup-function-name" {
  type        = string
  description = "Name of the Lambda function that cleans up S3 tmp buckets."
  default     = "rvcgs-cleanup-s3-playlist"
}

variable "upload-function-name" {
  type        = string
  description = "Name of the Lambda function that processes list_videos.txt uploads."
  default     = "rvcgs-upload"
}
