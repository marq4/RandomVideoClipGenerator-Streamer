locals {
  s3_bucket_mappings = {
    "backend" = {
      name        = local.s3_bucket_backend_name
      tag_purpose = "Store tfstate remotely"
      public      = false
      enable_acls = false
    }
    "scripts" = {
      name        = local.s3_bucket_scripts_name
      tag_purpose = "Storage for Python core and PowerShell scripts"
      public      = true
      enable_acls = false
    }
    "playlist" = {
      name        = local.s3_bucket_playlist_name
      tag_purpose = "Tmp storage for web browsers to download resulting XML playlist"
      public      = true
      enable_acls = false
    }
    "upload" = {
      name        = local.s3_bucket_upload_name
      tag_purpose = "Tmp storage for web browsers to upload video list text file to"
      public      = false
      enable_acls = false
    }

    # Website hosting + redirect buckets:
    "apex_com" = {
      name        = var.dns_domain_main_apex_dot_com_url
      tag_purpose = "Contains the web assets"
      public      = true
      enable_acls = true
    }
    "www_com" = {
      name        = "www.${var.dns_domain_main_apex_dot_com_url}"
      tag_purpose = "Redirects to apex domain"
      public      = true
      enable_acls = true
    }
    "apex_acronym_me" = {
      name        = var.dns_domain_acronym_url
      tag_purpose = "Redirects to about page"
      public      = true
      enable_acls = true
    }
    "www_acronym_me" = {
      name        = "www.${var.dns_domain_acronym_url}"
      tag_purpose = "Redirects to about page"
      public      = true
      enable_acls = true
    }
  }
}


resource "aws_s3_bucket" "s3_buckets" {
  for_each = local.s3_bucket_mappings
  bucket   = each.value.name
  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_s3_bucket_policy" "policies_for_all_buckets" {
  for_each   = local.s3_bucket_mappings
  bucket     = aws_s3_bucket.s3_buckets[each.key].id
  depends_on = [aws_s3_bucket_public_access_block.public_access] #XXX?
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "PreventDeletion"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:DeleteBucket"
        Resource  = aws_s3_bucket.s3_buckets[each.key].arn
      }],
      each.value.public ?
      [{
        Sid       = "PublicReadAllObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3_buckets[each.key].arn}/*"
      }]
      :
      []
    )
  })
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each = {
    for nickname, values in local.s3_bucket_mappings : nickname => values
    if values.public == true
  }
  bucket = aws_s3_bucket.s3_buckets[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning_for_backend" {
  bucket = aws_s3_bucket.s3_buckets["backend"].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "cors_for_upload" {
  bucket = aws_s3_bucket.s3_buckets["upload"].id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["https://${var.dns_domain_main_apex_dot_com_url}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}


resource "aws_s3_bucket_ownership_controls" "enable_acls_for_web_buckets" {
  for_each = {
    for nickname, values in local.s3_bucket_mappings : nickname => values
    if values.enable_acls == true
  }
  bucket = aws_s3_bucket.s3_buckets[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "web_hosting" {
  bucket = aws_s3_bucket.s3_buckets["apex_com"].id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  for_each = toset([
    "www_com",
    "apex_acronym_me",
    "www_acronym_me"
  ])
  bucket = aws_s3_bucket.s3_buckets[each.value].id

  redirect_all_requests_to {
    host_name = var.dns_domain_main_apex_dot_com_url
  }
}

# STYLE: no final dot on tags.
