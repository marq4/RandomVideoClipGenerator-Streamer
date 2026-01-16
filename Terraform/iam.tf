# TMP: just loading some values from ClickOps for now.

#TMP:
data "aws_iam_role" "core_role" {
  name = "AllowLambda2WriteLogs2CloudWatchRWS3AndInvokeOtherFunctions"
}

#TMP:
data "aws_iam_role" "list_role" {
  name = "respond_with_listmd_as_json-role-5a3esndg"
}

#TMP:
data "aws_iam_role" "cleanup_role" {
  name = "AllowDownstreamLambda2DeletePlaylistS3"
}

#TMP:
data "aws_iam_role" "upload_role" {
  name = "rvcgs-lambda-presigned-url-role"
}


#resource "aws_iam_role" "upload_role" {
#  name = "rvcgs-lambda-presigned-url-role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Action = "sts:AssumeRole"
#      Effect = "Allow"
#      Principal = {
#        Service = "lambda.amazonaws.com"
#      }
#    }]
#  })
#}

resource "aws_iam_role_policy_attachment" "upload_role_attachment" {
  role       = data.aws_iam_role.upload_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "upload_policy" {
  name = "s3-presigned-url-policy"
  role = data.aws_iam_role.upload_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.s3_buckets["upload"].arn}/*"
      }
    ]
  })
}
