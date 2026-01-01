# Main project's Region (default = no alias):
provider "aws" {
  region = var.ohio-code

  # All resources that use this provider will get the project tags:
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
