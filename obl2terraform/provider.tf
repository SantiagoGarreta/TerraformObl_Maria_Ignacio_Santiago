provider "aws"{
  profile = "SantiagoTerraform"
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.31.0"
    }
  }
}