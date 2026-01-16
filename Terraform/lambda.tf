locals {
  lambda_python_runtime = "python${local.python_version_entire_project}"

  # Python source code:
  local_lambda_path                                = "${local.local_cloud_folder_name}/${local.local_lambda_subfolder_name}"
  local_lambda_list_src_python_code_script_name    = "send_suggested_yt_video_list.py"
  local_lambda_list_src_python_code_path           = "${local.local_lambda_path}/${local.local_lambda_list_src_python_code_script_name}"
  local_lambda_cleanup_src_python_code_script_name = "s3_cleanup.py"
  local_lambda_cleanup_src_python_code_path        = "${local.local_lambda_path}/${local.local_lambda_cleanup_src_python_code_script_name}"
  local_lambda_upload_src_python_code_script_name  = "presigned_url_generator.py"
  local_lambda_upload_src_python_code_path         = "${local.local_lambda_path}/${local.local_lambda_upload_src_python_code_script_name}"

  # Temporary directories and zip files for Lambda deploy:
  ci_lambda_deploy_main_temp_zip_dir_name     = "main-lambda-package"
  ci_lambda_deploy_main_temp_zip_file_name    = "core_functionality.zip"
  ci_lambda_deploy_list_temp_zip_file_name    = "list_functionality.zip"
  ci_lambda_deploy_cleanup_temp_zip_dir_name  = "cleanup-lambda-package"
  ci_lambda_deploy_cleanup_temp_zip_file_name = "s3_cleanup_functionality.zip"
  ci_lambda_deploy_upload_temp_zip_dir_name   = "upload-lambda-package"
  ci_lambda_deploy_upload_temp_zip_file_name  = "upload_functionality.zip"

  lambda_function_mappings = {
    "core" = {
      name         = "rvcgs-core"
      description  = "Random Video Clip Generator Python core."
      handler      = "${trimsuffix(local.local_python_core_script_name, ".py")}.cloud_main"
      timeout      = 180 # 3 minutes.
      tag_purpose  = "Handles generate playlist + version + test values API calls"
      iam_role_arn = data.aws_iam_role.core_role.arn
      # Lambda code deployment not managed by Terraform:
      dummy_deployment_package = "dummy_core_functionality.zip"
    }
    "list" = {
      name         = "rvcgs-send-suggestions-list"
      description  = "Parses List.md from repo root into a JSON response for JS to display suggested YouTube music videos in the main page."
      handler      = "${trimsuffix(local.local_lambda_list_src_python_code_script_name, ".py")}.cloud_main"
      timeout      = 3 #seconds.
      tag_purpose  = "Handles list API call"
      iam_role_arn = data.aws_iam_role.list_role.arn
      # Lambda code deployment not managed by Terraform:
      dummy_deployment_package = "dummy_list_md_functionality.zip"
    }
    "cleanup" = {
      name         = "rvcgs-cleanup-s3-playlist"
      description  = "Deletes clips.xspf from bucket right after it's sent to user's browser for download."
      handler      = "${trimsuffix(local.local_lambda_cleanup_src_python_code_script_name, ".py")}.lambda_handler"
      timeout      = 20 #seconds.
      tag_purpose  = "Gets triggered after generate success"
      iam_role_arn = data.aws_iam_role.cleanup_role.arn
      # Lambda code deployment not managed by Terraform:
      dummy_deployment_package = "dummy_s3_cleanup_functionality.zip"
    }
    "upload" = {
      name         = "rvcgs-upload"
      description  = "Generates presigned S3 URL for user upload."
      handler      = "${trimsuffix(local.local_lambda_upload_src_python_code_script_name, ".py")}.lambda_handler"
      timeout      = 23 #seconds.
      tag_purpose  = "Gets triggered after upload API call"
      iam_role_arn = data.aws_iam_role.upload_role.arn
      # Lambda code deployment not managed by Terraform:
      dummy_deployment_package = "dummy_upload_functionality.zip"
    }
  }
}


resource "aws_lambda_function" "lambda_functions" {
  for_each = local.lambda_function_mappings

  function_name = each.value.name
  description   = each.value.description
  handler       = each.value.handler
  timeout       = each.value.timeout
  filename      = each.value.dummy_deployment_package
  role          = each.value.iam_role_arn

  runtime = local.lambda_python_runtime

  tags = merge(
    {
      Purpose = each.value.tag_purpose
    },
    local.cloud_common_tags
  )

  lifecycle {
    prevent_destroy = true
  }
}
