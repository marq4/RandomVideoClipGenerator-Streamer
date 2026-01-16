# Variables and locals.
# Single source of truth for entire project.
# All thing's names must be specified here (only once).


# === MAIN / Project ===

variable "cloud_project_name_tag" {
  type        = string
  description = "Project name for AWS tags."
  default     = "RVCGS service serverless"
}

variable "dns_domain_main_apex_dot_com_url" {
  type        = string
  description = "Apex.com domain URL. Also name of the web hosting bucket."
  default     = "randomvideoclipgenerator.com"
  # TODO: replace all instances of that value anywhere with a REF to this var.
}

# ALSO update name here IF I ever decide to rename any of these:
locals {
  # Folders:
  local_cloud_folder_name     = "CloudWebService"
  local_web_subfolder_name    = "WebAssets"
  local_js_subfolder_name     = "JS"
  local_html_subfolder_name   = "HTML"
  local_css_subfolder_name    = "CSS"
  local_core_folder_name      = "PythonCore"
  local_lambda_subfolder_name = "LambdaCode"

  # Bash scripts:
  local_verify_s3_deploy_aux_bash_script_path = ".github/scripts/verify_deployed_version.sh"
}


# === WEB ===

variable "ci_nodejs_version" {
  type        = string
  description = "Version of NodeJS to be setup in CI env to lint web assets."
  default     = "20"
}

locals {
  local_web_path = "${local.local_cloud_folder_name}/${local.local_web_subfolder_name}"
}

# HTML:
locals {
  # Names:
  html_main_name              = "index.html"
  html_generate_playlist_name = "generate-playlist.html"

  # HTML templates and documents:
  local_html_path                   = "${local.local_web_path}/${local.local_html_subfolder_name}"
  local_html_main_index_path        = "${local.local_html_path}/${local.html_main_name}"
  local_html_generate_playlist_path = "${local.local_html_path}/${local.html_generate_playlist_name}"
  html_template_mappings = {
    "html_main_index" = {
      local_src_template_path = "../${local.local_html_main_index_path}.tpl"
      local_document_path     = "../${local.local_html_main_index_path}"
      remote_html_target_path = "${local.local_html_subfolder_name}/${local.html_main_name}"
    }
    # "html_about_index" = {}
    "html_generate_playlist" = {
      local_src_template_path = "../${local.local_html_generate_playlist_path}.tpl"
      local_document_path     = "../${local.local_html_generate_playlist_path}"
      remote_html_target_path = "${local.local_html_subfolder_name}/${local.html_generate_playlist_name}"
    }
    # "html_docker_generator_index" = {}
  }
  # Text content:
  html_install_ffmpeg_text                = "Install <a href=\"${local.external_install_ffmpeg_tutorial_url}\">FFmpeg</a>."
  html_download_music_videos_contact_text = <<-EOT
    Download some music videos there
     (<a href="mailto:juancmarquina@gmail.com">contact me</a> for instructions).
  EOT
  html_install_vlc_text                   = "Install <a href=\"${local.external_vlc_url}\">VLC</a>."
}

# JavaScript:
locals {
  # Names:
  js_tabs_name              = "tabs-functionality.js"
  js_generate_playlist_name = "call-generate-playlist.js"
  js_version_name           = "display-version.js"
  js_upload_name            = "upload-user-local-video-list-durations-text-file.js"
  js_list_name              = "load-suggested-music-video-list.js"

  # JavaScript templates and scripts:
  local_js_path                   = "${local.local_web_path}/${local.local_js_subfolder_name}"
  local_js_generate_playlist_path = "${local.local_js_path}/${local.js_generate_playlist_name}"
  local_js_version_path           = "${local.local_js_path}/${local.js_version_name}"
  local_js_upload_path            = "${local.local_js_path}/${local.js_upload_name}"
  local_js_list_path              = "${local.local_js_path}/${local.js_list_name}"
  remote_js_tabs_target_path      = "${local.local_js_subfolder_name}/${local.js_tabs_name}"
  js_template_mappings = {
    "generate" = {
      local_src_template_path = "../${local.local_js_generate_playlist_path}.tpl"
      local_script_path       = "../${local.local_js_generate_playlist_path}"
      # We can't get these values from the proper APIGW resources as they also contain the method (GET/POST):
      apigw_route_value     = local.apigw_generate_route_path
      remote_js_target_path = "${local.local_js_subfolder_name}/${local.js_generate_playlist_name}"
    }
    "version" = {
      local_src_template_path = "../${local.local_js_version_path}.tpl"
      local_script_path       = "../${local.local_js_version_path}"
      apigw_route_value       = local.apigw_version_route_path
      remote_js_target_path   = "${local.local_js_subfolder_name}/${local.js_version_name}"
    }
    "upload" = {
      local_src_template_path = "../${local.local_js_upload_path}.tpl"
      local_script_path       = "../${local.local_js_upload_path}"
      apigw_route_value       = local.apigw_upload_route_path
      remote_js_target_path   = "${local.local_js_subfolder_name}/${local.js_upload_name}"
    }
    "list" = {
      local_src_template_path = "../${local.local_js_list_path}.tpl"
      local_script_path       = "../${local.local_js_list_path}"
      apigw_route_value       = local.apigw_list_route_path
      remote_js_target_path   = "${local.local_js_subfolder_name}/${local.js_list_name}"
    }
  }

  # Template variables shared by all JS files that call APIGW:
  js_template_vars = {
    endpoint = aws_apigatewayv2_api.apigw_http_api.api_endpoint
    stage    = aws_apigatewayv2_stage.apigw_prod_stage.name
  }
}


# === Python ===

locals {
  # Must be string or becomes 3.1 as number:
  python_version_entire_project = "3.10"
  local_python_core_script_name = "random_video_clip_generator.py"
  local_python_core_script_path = "${local.local_core_folder_name}/${local.local_python_core_script_name}"
}

variable "ci_python_skip_testing_option" {
  type        = bool
  description = "Whether to skip pytest job."
  # Set to false to enable Python testing in CI (and apply):
  default = true
}

variable "ci_python_skip_code_quality_option" {
  type        = bool
  description = "Whether to skip pylint, etc job."
  # Set to false to enable Python linting in CI (and apply):
  default = true
}

variable "ci_python_unit_testing_code_coverage_value" {
  type        = number
  description = "Specify minimum code coverage for Unit Testing (real target: 80)."
  # Set to 0 to disable code coverage (Python) checking (and apply):
  default = 40
}


# === Cloud ===

variable "cloud_project_region_main_selector" {
  type        = string
  description = "Main Region for project."
  # No default. Apply with: -var-file="prod.tfvars"
}

locals {
  # All AWS resources that support tags get these:
  cloud_common_tags = {
    ManagedBy = "Terraform"
    Project   = var.cloud_project_name_tag
  }

  cloud_region_codes_aux = {
    Ohio      = "us-east-2"
    NVirginia = "us-east-1"
    Ireland   = "eu-west-1"
  }

  cloud_selected_region = local.cloud_region_codes_aux[var.cloud_project_region_main_selector]
}

# S3 bucket names:
locals {
  # Should this be a var? It would change in case of regional failure:
  common_prefix           = "rvcgs-marq"
  s3_bucket_backend_name  = "${local.common_prefix}-remote-state-backend-30122025"
  s3_bucket_scripts_name  = "${local.common_prefix}-scripts-30122025"
  s3_bucket_playlist_name = "${local.common_prefix}-xspf-playlist-31122025"
  s3_bucket_upload_name   = "${local.common_prefix}-list-videos-upload-05012026"
}

# CloudFront:
variable "cloudfront_distribution_id" {
  type        = string
  description = "TODO: import CloudFront infra into Tf."
  default     = "EWDPJFG1ZNBMV"
}

# DNS:
variable "dns_domain_acronym_url" {
  type        = string
  description = "Short alternative URL that points directly to about page."
  default     = "rvcg.me"
}


# === External ===

locals {
  # URLs:
  external_install_ffmpeg_tutorial_url = "https://www.youtube.com/watch?v=DMEP82yrs5g"
  external_vlc_url                     = "https://www.videolan.org/vlc/"
}


# STYLE: End descriptions with period. (TODO: enforce with tflint?)
# STYLE: snake_case for everything.
