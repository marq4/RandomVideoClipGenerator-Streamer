# Main project's Region (default = no alias):
provider "aws" {
  region = local.cloud_selected_region

  # All resources that use this provider will get the project tags:
  default_tags {
    tags = local.cloud_common_tags
  }
}

# Region for ACM certs MUST BE North Virginia:
provider "aws" {
  region = local.region_codes["NVirginia"]
  alias  = "nvirginia"

  default_tags {
    tags = local.cloud_common_tags
  }
}
