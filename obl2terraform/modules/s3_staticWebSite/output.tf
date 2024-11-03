output "website_url" {
  description = "La URL del sitio web estático en S3"
  value       = aws_s3_bucket.static_site.bucket_regional_domain_name
}