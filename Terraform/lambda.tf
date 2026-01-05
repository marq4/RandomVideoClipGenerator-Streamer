resource "aws_lambda_function" "core-function" {
  function_name = var.core-function-name
  description   = "Random Video Clip Generator Python core."

  runtime = var.lambda-runtime
  handler = "random_video_clip_generator.cloud_main"
  timeout = 180 # 3 minutes.

  tags = {
    Purpose = "Handles /generate playlist + /version + /testvalues API calls"
  }

  role = data.aws_iam_role.core-role.arn

  # Code:
  filename = "corefunctionality.zip"
}

resource "aws_lambda_function" "list-function" {
  function_name = var.list-function-name
  description   = "Parses List.md from repo root into a JSON response for JS to display suggested YouTube music videos in the main page."

  runtime = var.lambda-runtime
  handler = "send_suggested_yt_video_list.cloud_main"
  timeout = 3 #seconds.

  tags = {
    Purpose = "Handles /list API call"
  }

  role = data.aws_iam_role.list-role.arn

  # Code:
  filename = "listmdfunctionality.zip"
}

resource "aws_lambda_function" "cleanup-function" {
  function_name = var.cleanup-function-name
  description   = "Deletes clips.xspf from bucket right after it's sent to user's browser for download."

  runtime = var.lambda-runtime
  handler = "s3_cleanup.lambda_handler"
  timeout = 20 #seconds.

  tags = {
    Purpose = "Gets triggered after /generate success."
  }

  role = data.aws_iam_role.cleanup-role.arn

  # Code:
  filename = "s3cleanupfunctionality.zip"
}

resource "aws_lambda_function" "upload-function" {
  function_name = var.upload-function-name
  description   = "Generates presigned S3 URL for user upload."

  runtime = var.lambda-runtime
  handler = "presigned_url_generator.lambda_handler"
  timeout = 23 #seconds.

  tags = {
    Purpose = "Gets triggered after /upload API call."
  }

  role = aws_iam_role.upload-role.arn

  # Code:
  filename = "uploadfunctionality.zip"
}
