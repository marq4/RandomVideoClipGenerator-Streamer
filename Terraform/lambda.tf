resource "aws_lambda_function" "core-function" {
  function_name = "rvcgs-core"
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
  function_name = "rvcgs-send-suggestions-list"
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
  function_name = "rvcgs-cleanup-s3-playlist"
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
