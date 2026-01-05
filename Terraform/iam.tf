# Just loading from ClickOps for now:

#TMP:
data "aws_iam_role" "core-role" {
  name = "AllowLambda2WriteLogs2CloudWatchRWS3AndInvokeOtherFunctions"
}

#TMP:
data "aws_iam_role" "list-role" {
  name = "respond_with_listmd_as_json-role-5a3esndg"
}

#TMP:
data "aws_iam_role" "cleanup-role" {
  name = "AllowDownstreamLambda2DeletePlaylistS3"
}

resource "aws_iam_role" "upload-role" {
  name = "rvcgs-lambda-presigned-url-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "upload-role-attachment" {
  role       = aws_iam_role.upload-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "upload-policy" {
  name = "s3-presigned-url-policy"
  role = aws_iam_role.upload-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.upload-bucket.arn}/*"
      }
    ]
  })
}
