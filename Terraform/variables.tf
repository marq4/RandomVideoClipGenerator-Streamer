# Variables AND locals.
# Single source of truth for entire project.
# All thing's names must be specified here (only once).

# STYLE: End descriptions with period. (TODO: enforce with tflint?)
# STYLE: locals with snake_case.

# === MAIN / Project ===

variable "project-name" {
  type        = string
  description = "Project name for tags."
  default     = "RVCGS/serverless"
}

variable "main-dot-com-apex-url" {
  type        = string
  description = "Apex.com domain URL. Also the name of the web hosting bucket."
  default     = "randomvideoclipgenerator.com"
  # TODO: replace all instances of that value anywhere with a REF to this var.
}

# ALSO update name here IF I ever decide to rename this top-level folder:
variable "local-cloud-folder-name" {
  type        = string
  description = "Name of Cloud/Web folder (lives in project root)."
  default     = "CloudService"
}

# ALSO update name here IF I ever decide to rename this subfolder:
variable "local-js-subfolder-name" {
  type        = string
  description = "Subfolder inside Web folder that contains js templates and JavaScripts."
  default     = "JS"
}

# ALSO update name here IF I ever decide to rename this top-level folder:
variable "local-core-folder-name" {
  type        = string
  description = "Name of Python core folder (lives in project root)."
  default     = "PythonCore"
}

# Bash scripts:

variable "local-bash-aux-script-verify-s3-deploy-path" {
  type        = string
  description = "Aux script used to verify version of core script deployed to S3 matches latest Release on GitHub."
  default     = ".github/scripts/verify_deployed_version.sh"
}


# === WEB ===

variable "ci-nodejs-version" {
  type        = string
  description = "Version of NodeJS to be setup in CI env to lint web assets."
  default     = "20"
}

# HTML:

locals {
  html_index_template_path           = "${var.local-cloud-folder-name}/index.html.template"
  text_install_ffmpeg                = "Install <a href=\"https://www.youtube.com/watch?v=DMEP82yrs5g\">FFmpeg</a>."
  text_download_music_videos_contact = <<-EOT
    Download some music videos there
     (<a href="mailto:juancmarquina@gmail.com">contact me</a> for instructions).
  EOT
  text_install_vlc                   = "Install <a href=\"https://www.videolan.org/vlc/\">VLC</a>."
}

# JavaScript:

locals {
  # JavaScript templates and scripts:
  js_path                          = "${var.local-cloud-folder-name}/${var.local-js-subfolder-name}"
  generate_playlist_js_path_no_ext = "${local.js_path}/${var.js-generate-playlist-name-no-ext}"
  version_js_path_no_ext           = "${local.js_path}/${var.js-version-name-no-ext}"
  upload_js_path_no_ext            = "${local.js_path}/${var.js-upload-name-no-ext}"
  list_js_path_no_ext              = "${local.js_path}/${var.js-list-name-no-ext}"
  tabs_js_path                     = "${local.js_path}/${var.js-tabs-name}"
  js_files = {
    "generate-js" = {
      src_template = "../${local.generate_playlist_js_path_no_ext}.js.tpl"
      script_name  = "../${local.generate_playlist_js_path_no_ext}.js"
      path         = var.apigw-generate-route-path
    }
    "version-js" = {
      src_template = "../${local.version_js_path_no_ext}.js.tpl"
      script_name  = "../${local.version_js_path_no_ext}.js"
      path         = var.apigw-version-route-path
    }
    "upload-js" = {
      src_template = "../${local.upload_js_path_no_ext}.js.tpl"
      script_name  = "../${local.upload_js_path_no_ext}.js"
      path         = var.apigw-upload-route-path
    }
    "list-js" = {
      src_template = "../${local.list_js_path_no_ext}.js.tpl"
      script_name  = "../${local.list_js_path_no_ext}.js"
      path         = var.apigw-list-route-path
    }
  }

  # Template variables shared by all JS files that call APIGW:
  js_template_vars = {
    endpoint = aws_apigatewayv2_api.rvcgs-http-api.api_endpoint
    stage    = aws_apigatewayv2_stage.prod-stage.name
  }
}

# JS names (STYLE: use kebab-case):

# ALSO update name here IF I ever decide to rename this JavaScript:
variable "js-tabs-name" {
  type        = string
  description = "Script name that contains tabs functionality."
  default     = "tabs-functionality.js"
}

# ALSO update name here IF I ever decide to rename this JS template:
variable "js-generate-playlist-name-no-ext" {
  type        = string
  description = "Bare script name used for both .js and .js.tpl. Sets click of generate playlist page/GENERATE PLAYLIST button to POST user selections."
  default     = "call-generate-playlist"
}

# ALSO update name here IF I ever decide to rename this JS template:
variable "js-version-name-no-ext" {
  type        = string
  description = "Bare script name used for both .js and .js.tpl. Fetches project's version on main page load and places it in footer."
  default     = "display-version"
}

# ALSO update name here IF I ever decide to rename this JS template:
variable "js-upload-name-no-ext" {
  type        = string
  description = "Bare script name used for both .js and .js.tpl. Requests S3 pre-signed URL to allow uploading user's text file to 'upload' bucket."
  default     = "upload-user-local-video-list-durations-text-file"
}

# ALSO update name here IF I ever decide to rename this JS template:
variable "js-list-name-no-ext" {
  type        = string
  description = "Bare script name used for both .js and .js.tpl. Retrieves contents of List.md from repo and parses into HTML."
  default     = "load-suggested-music-video-list"
}


# === Python ===

locals {
  # Must be string or becomes 3.1 as number:
  python_version_entire_project = "3.10"
  # All functions share the same runtime:
  lambda_runtime = "python${local.python_version_entire_project}"

  python_core_script_local_path = "${var.local-core-folder-name}/${var.local-python-core-script-name}"
}

# ALSO update name here IF I ever decide to rename this file:
variable "local-python-core-script-name" {
  type        = string
  description = "Critical and fundamental Python code deployed both as a simple script to S3, and for main Lambda."
  default     = "random_video_clip_generator.py"
}

variable "ci-python-skip-testing-option" {
  type        = bool
  description = "Whether to skip pytest job."
  # Set to false to enable Python testing in CI (and apply):
  default = true
}

variable "ci-python-skip-code-quality-option" {
  type        = bool
  description = "Whether to skip pylint, etc job."
  # Set to false to enable Python linting in CI (and apply):
  default = true
}

variable "ci-python-unit-testing-code-coverage-option" {
  type        = number
  description = "Specify minimum code coverage for Unit Testing (real target: 80)."
  # Set to 0 to disable code coverage (Python) checking:
  default = 40
}


# === Cloud ===

variable "project-aws-main-region-name" {
  type        = string
  description = "Main Region for project."
  # No default. Apply with: -var-file="prod.tfvars"
}

locals {
  # All AWS resources that support tags get these:
  common_tags = {
    ManagedBy = "Terraform"
    Project   = var.project-name
  }

  region_codes = {
    Ohio      = "us-east-2"
    NVirginia = "us-east-1"
    Ireland   = "eu-west-1"
  }

  aws_selected_region = local.region_codes[var.project-aws-main-region-name]
}

# S3:

variable "s3-backend-bucket-name" {
  type        = string
  description = "Name of the bucket used to store remote state."
  default     = "rvcgs-marq-remote-state-backend-30122025"
}

variable "s3-scripts-bucket-name" {
  type        = string
  description = "Name of the bucket that hosts core Python and PowerShell scripts."
  default     = "rvcgs-marq-scripts-30122025"
}

variable "s3-playlist-bucket-name" {
  type        = string
  description = "Name of the bucket where Lambda writes clips.xspf to."
  default     = "rvcgs-marq-xspf-playlist-31122025"
}

variable "s3-upload-bucket-name" {
  type        = string
  description = "Name of the bucket where list_videos.txt is temporarily uploaded to."
  default     = "rvcgs-marq-list-videos-upload-05012026"
}


# Lambda:

variable "local-lambda-src-subfolder-name" {
  type        = string
  description = "Name of the subfolder that contains Lambda source code (lives inside Cloud folder)."
  default     = "LambdaCode"
}

variable "lambda-core-function-name" {
  type        = string
  description = "Name of the main Lambda function."
  default     = "rvcgs-core"
}

variable "lambda-list-function-name" {
  type        = string
  description = "Name of the Lambda function that sends the suggested YouTube music video list."
  default     = "rvcgs-send-suggestions-list"
}

variable "local-lambda-src-code-list-script-name" {
  type        = string
  description = "Name of the Python source code for list Lambda."
  default     = "send_suggested_yt_video_list.py"
}

variable "lambda-cleanup-function-name" {
  type        = string
  description = "Name of the Lambda function that cleans up S3 buckets for temporary storage."
  default     = "rvcgs-cleanup-s3-playlist"
}

variable "local-lambda-src-code-cleanup-script-name" {
  type        = string
  description = "Name of the Python source code for cleanup Lambda."
  default     = "s3_cleanup.py"
}

variable "lambda-upload-function-name" {
  type        = string
  description = "Name of the Lambda function that processes user upload."
  default     = "rvcgs-upload"
}

variable "local-lambda-src-code-upload-script-name" {
  type        = string
  description = "Name of the Python source code for upload Lambda."
  default     = "presigned_url_generator.py"
}

# Temporary directories and zip files for Lambda deploy:

variable "ci-lambda-main-temp-zip-dir-name" {
  type        = string
  description = "To deploy script + dependencies to main Lambda."
  default     = "main-lambda-package"
}

variable "ci-lambda-main-temp-zip-file-name" {
  type        = string
  description = "Name of the zip file with script + dependencies to be deployed to main Lambda."
  default     = "core_functionality.zip"
}

variable "ci-lambda-list-temp-zip-file-name" {
  type        = string
  description = "Name of the zip file with script to be deployed to list Lambda."
  default     = "list_functionality.zip"
}

variable "ci-lambda-cleanup-temp-zip-dir-name" {
  type        = string
  description = "To deploy script + dependencies to cleanup Lambda."
  default     = "cleanup-lambda-package"
}

variable "ci-lambda-cleanup-temp-zip-file-name" {
  type        = string
  description = "Name of the zip file with script + dependencies to be deployed to cleanup Lambda."
  default     = "s3_cleanup_functionality.zip"
}

variable "ci-lambda-upload-temp-zip-dir-name" {
  type        = string
  description = "To deploy script + dependencies to upload Lambda."
  default     = "upload-lambda-package"
}

variable "ci-lambda-upload-temp-zip-file-name" {
  type        = string
  description = "Name of the zip file with script + dependencies to be deployed to upload Lambda."
  default     = "upload_functionality.zip"
}

locals {
  lambda_path                        = "${var.local-cloud-folder-name}/${var.local-lambda-src-subfolder-name}"
  list_python_code_src_local_path    = "${local.lambda_path}/${var.local-lambda-src-code-list-script-name}"
  cleanup_python_code_src_local_path = "${local.lambda_path}/${var.local-lambda-src-code-cleanup-script-name}"
  upload_python_code_src_local_path  = "${local.lambda_path}/${var.local-lambda-src-code-upload-script-name}"
}


# API GW:

# API name:
variable "apigw-api-name" {
  type        = string
  description = "Name of the API for this project."
  default     = "RVCGS-API"
}

# Stage name:
variable "apigw-stage-name" {
  type        = string
  description = "PROD APIGW stage name (no '/')."
  default     = "prod"
}

# Route paths:

variable "apigw-generate-route-path" {
  type        = string
  description = "API GW route path (with '/') for playlist generation endpoint."
  default     = "/generate"
}

variable "apigw-version-route-path" {
  type        = string
  description = "API GW route path (with '/') for project version retrieval endpoint."
  default     = "/version"
}

variable "apigw-upload-route-path" {
  type        = string
  description = "API GW route path (with '/') for user's text file upload endpoint."
  default     = "/upload"
}

variable "apigw-list-route-path" {
  type        = string
  description = "API GW route path (with '/') for suggested music video list retrieval endpoint."
  default     = "/list"
}

variable "apigw-test-values-route-path" {
  # Not used by JS.
  type        = string
  description = "API GW route path (with '/') for values (num_clips, min, max) curl testing endpoint."
  default     = "/testvalues"
}


# CloudFront:

variable "cloudfront-distribution-id" {
  type        = string
  description = "TODO: this has to be an output after importing CloudFront infra into Tf."
  default     = "EWDPJFG1ZNBMV"
}


# DNS:

variable "acronym-domain" {
  type        = string
  description = "Short and sweet alternative URL that points directly to about page."
  default     = "rvcg.me"
}
