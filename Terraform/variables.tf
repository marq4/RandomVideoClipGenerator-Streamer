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
