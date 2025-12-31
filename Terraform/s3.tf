# Remote state:

# Store tfstate remotely:
resource "aws_s3_bucket" "rvcgs-backend-bucket" {
  bucket   = var.backend-bucket-name
  provider = aws.ohio
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning-for-backend" {
  bucket = aws_s3_bucket.rvcgs-backend-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# Scripts bucket:

resource "aws_s3_bucket" "scripts-bucket" {
  bucket   = var.scripts-bucket-name
  provider = aws.ohio
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Purpose = "Storage for Python core and PowerShell scripts"
  }
}

# Scripts must be publicly accessible:
resource "aws_s3_bucket_public_access_block" "public-access-for-scripts" {
  bucket = aws_s3_bucket.scripts-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Inline JSON for dynamic ARN:
resource "aws_s3_bucket_policy" "policy-for-scripts" {
  bucket = aws_s3_bucket.scripts-bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public-access-for-scripts]

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.scripts-bucket.arn}/*"
      },
      {
        "Sid" : "PreventDeletion",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:DeleteBucket",
        "Resource" : aws_s3_bucket.scripts-bucket.arn
      }
    ]
  })
}


# Playlist bucket:

resource "aws_s3_bucket" "playlist-bucket" {
  bucket   = var.playlist-bucket-name
  provider = aws.ohio
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Purpose = "Tmp storage for web browsers to download resulting XML playlist"
  }
}

resource "aws_s3_bucket_public_access_block" "public-access-for-playlist" {
  bucket = aws_s3_bucket.playlist-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "policy-for-playlist" {
  bucket = aws_s3_bucket.playlist-bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PreventDeletion",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:DeleteBucket",
        "Resource" : aws_s3_bucket.playlist-bucket.arn
      }
    ]
  })
}
