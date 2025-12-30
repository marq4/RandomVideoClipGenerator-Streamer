# Remote state:

# Store tfstate remotely:
resource "aws_s3_bucket" "rvcgs-backend-bucket" {
  bucket   = var.backend-bucket-name
  provider = aws.ohio
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.rvcgs-backend-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
