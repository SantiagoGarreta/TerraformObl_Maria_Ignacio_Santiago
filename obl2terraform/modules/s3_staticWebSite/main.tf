resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.static_site]
}

resource "aws_s3_object" "banking_html" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "banking/transactions.html"
  source       = "${path.module}/static/banking/transactions.html"
  content_type = "text/html"
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "banking/config.js"
  content      = "const CONFIG = { API_ENDPOINT: '${var.api_endpoint}' };"
  content_type = "application/javascript"
}

resource "aws_s3_object" "angular_app" {
  for_each = fileset(var.angular_app_path, "**/*")

  bucket       = aws_s3_bucket.static_site.id
  key          = "app/${each.value}"
  source       = "${var.angular_app_path}/${each.value}"
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), "application/octet-stream")
  etag         = filemd5("${var.angular_app_path}/${each.value}")
}

locals {
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
  }
}