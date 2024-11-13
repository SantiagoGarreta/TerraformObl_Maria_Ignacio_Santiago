module "s3_static_site" {
  source       = "./modules/s3_staticWebSite"
  bucket_name  = "bucket-s3-static-website-obl-2024-ms"
  api_endpoint  = module.api_gateway.api_endpoint  # Now matches the output name
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

module "s3_storageService" {
  source             = "./modules/s3_storageService"
  bucket_name_primary   = "user-docs-primary-obl2-2024-ms"    
  bucket_name_secondary = "user-docs-secondary-obl2-2024-ms"  
  region_secondary      = "us-west-1"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
}

module "sns_sqs" {
  source     = "./modules/notifications"
  queue_name = "example-queue"
  topic_name = "example-topic"
}

module "bank_transaction_processing" {
  source                = "./modules/bank_transaction_processing"
  bucket_name          = "bank-transaction-uploads-2024-ms"  
  lambda_function_name  = "TransactionProcessorFunction"
  lambda_runtime        = "nodejs18.x"
  lambda_handler        = "index.handler"
  lambda_zip_file       = "./modules/bank_transaction_processing/function.zip" 
  authorized_user_arn   = "arn:aws:iam::423623837482:user/NoeTerraform" //usar el ARN del usuario
}

module "lambda" {
  source = "./modules/lambda"
  environment   = var.environment
  api_gateway_execution_arn = module.api_gateway.execution_arn
  lambda_function_name = "transaction_processor"
  db_host     = module.rds.rds_endpoint
  db_name     = module.rds.rds_database_name
  db_user     = var.db_username
  db_password = var.db_password
  db_port     = module.rds.rds_port
}


module "api_gateway" {
  source = "./modules/api_gateway"

  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  lambda_arn          = module.lambda.function_arn
  api_name            = "transaction_api"
}


data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.environment}-lambda-sg"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-lambda-sg"
    Environment = var.environment
  }
}

module "rds" {
  source = "./modules/rds"

  environment         = var.environment
  vpc_id             = data.aws_vpc.default.id
  private_subnet_ids = data.aws_subnets.default.ids
  lambda_security_group_id = aws_security_group.lambda.id

  database_name     = "banking_db"
  database_username = var.db_username
  database_password = var.db_password
}