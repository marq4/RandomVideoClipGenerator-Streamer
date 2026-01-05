# Remote state:

# Store tfstate remotely:
resource "aws_s3_bucket" "rvcgs-backend-bucket" {
  bucket = var.backend-bucket-name
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
  bucket = var.scripts-bucket-name
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
  bucket = var.playlist-bucket-name
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


# Upload bucket:

resource "aws_s3_bucket" "upload-bucket" {
  bucket = var.upload-bucket-name
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Purpose = "Tmp storage for web browsers to upload video list text file to"
  }
}

resource "aws_s3_bucket_policy" "policy-for-upload" {
  bucket = aws_s3_bucket.upload-bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PreventDeletion",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:DeleteBucket",
        "Resource" : aws_s3_bucket.upload-bucket.arn
      }
    ]
  })
}



# Website-hosting buckets:

# 1.- Apex.com: randomvideoclipgenerator.com:

resource "aws_s3_bucket" "apex-dot-com-bucket" {
  bucket = var.main-dot-com-apex-url

  tags = {
    Purpose = "Contains assets for website hosting"
  }
}

resource "aws_s3_bucket_public_access_block" "public-access-for-apex" {
  bucket = aws_s3_bucket.apex-dot-com-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "enable-acls-apex" {
  bucket = aws_s3_bucket.apex-dot-com-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "web-hosting" {
  bucket = aws_s3_bucket.apex-dot-com-bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "policy-for-apex-dot-com" {
  bucket = aws_s3_bucket.apex-dot-com-bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public-access-for-apex]

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.apex-dot-com-bucket.arn}/*"
      }
    ]
  })
}

# 2.- WWW.com: www.randomvideoclipgenerator.com:

resource "aws_s3_bucket" "www-dot-com-bucket" {
  bucket = "www.randomvideoclipgenerator.com"

  tags = {
    Purpose = "Redirect to apex domain"
  }
}

resource "aws_s3_bucket_public_access_block" "public-access-for-www-com" {
  bucket = aws_s3_bucket.www-dot-com-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "enable-acls-www-com" {
  bucket = aws_s3_bucket.www-dot-com-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "www-redirect" {
  bucket = aws_s3_bucket.www-dot-com-bucket.id

  redirect_all_requests_to {
    host_name = var.main-dot-com-apex-url
  }
}

# 3.- Apex-acronym.me: rvcg.me:

resource "aws_s3_bucket" "apex-acronym-dot-me-bucket" {
  bucket = "rvcg.me"

  tags = {
    Purpose = "Redirect to main site"
  }
}

resource "aws_s3_bucket_public_access_block" "public-access-for-acronym" {
  bucket = aws_s3_bucket.apex-acronym-dot-me-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "enable-acls-acronym" {
  bucket = aws_s3_bucket.apex-acronym-dot-me-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "acronym-redirect" {
  bucket = aws_s3_bucket.apex-acronym-dot-me-bucket.id

  redirect_all_requests_to {
    host_name = var.main-dot-com-apex-url
  }
}

# 4.- WWW-acronym.me: www.rvcg.me:

resource "aws_s3_bucket" "www-acronym-dot-me-bucket" {
  bucket = "www.rvcg.me"

  tags = {
    Purpose = "Redirect to main site"
  }
}

resource "aws_s3_bucket_public_access_block" "public-access-for-www-acronym" {
  bucket = aws_s3_bucket.www-acronym-dot-me-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "enable-acls-www-acronym" {
  bucket = aws_s3_bucket.www-acronym-dot-me-bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "www-acronym-redirect" {
  bucket = aws_s3_bucket.www-acronym-dot-me-bucket.id

  redirect_all_requests_to {
    host_name = var.main-dot-com-apex-url
  }
}
