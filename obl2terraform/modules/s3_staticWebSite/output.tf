output "website_url" {
  description = "La URL del sitio web estático en S3"
  value       = aws_s3_bucket_website_configuration.static_site_website.website_endpoint
}