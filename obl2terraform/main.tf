resource "aws_s3_bucket" "bucket" {
    bucket = "terraformsantiagogarreta"

    tags = {
        Name = "My bucket"
        Environment = "Dev"
    }
  
}

module "s3_static_site" {
  source      = "./modules/s3_staticWebSite"
  bucket_name = "bucket-s3-static-website-obligatorio"
  tags = {
    Environment = "Production"
    Project     = "Static Website"
  }
}