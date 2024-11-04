/*resource "aws_s3_bucket" "bucket" {
    bucket = "terraformsantiagogarreta"

    tags = {
        Name = "My bucket"
        Environment = "Dev"
    }
  
}
*/

module "s3_static_site" {
  source      = "./modules/s3_staticWebSite"
  bucket_name = "bucket-s3-static-website-obligatorio"
  tags = {
    Environment = "Production"
    Project     = "Static Website"
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = module.s3_static_site.website_url
    origin_id   = "S3-static-site-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-static-site-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_url" {
  description = "La URL de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.cdn.domain_name
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "owner-id"
    values = ["137112412989"]
  }
}

module "ec2_Instance" {
  source        = "./modules/ec2_Instance"
  ami_id        = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  instance_name = "example-web-instance"
}