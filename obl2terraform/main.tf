resource "aws_s3_bucket" "bucket" {
    bucket = "terraformsantiagogarreta"

    tags = {
        Name = "My bucket"
        Environment = "Dev"
    }
  
}