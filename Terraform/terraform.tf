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
    # Variables cannot be used here:
    bucket = "rvcgs-marq-remote-state-backend-30122025"
    # NOT repeating that requires advanced hacks!
    key    = "terraform-state-file"
    region = "us-east-2" # TODO: can I specify this ONLY ONCE??
  }
}
