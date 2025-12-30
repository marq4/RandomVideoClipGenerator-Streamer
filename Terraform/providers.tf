locals {
  common_tags = {
    ManagedBy = "Terraform"
    Project   = var.project
  }
}

# Main project's Region:
provider "aws" {
  region = var.ohio-code
  alias  = "ohio"

  default_tags {
    tags = local.common_tags
  }
}

# Region for ACM certs:
provider "aws" {
  region = var.north-virginia-code
  alias  = "nvirginia"

  default_tags {
    tags = local.common_tags
  }
}
