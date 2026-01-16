terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2"
    }
  }

  backend "s3" {
    key = "terraform-state-file"
    # Bucket and Region specified at init time.
    # Do: init -backend-config=backend-prod.tfvars
  }
}
