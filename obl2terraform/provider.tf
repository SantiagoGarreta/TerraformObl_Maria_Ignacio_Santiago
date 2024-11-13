provider "aws" {
  profile = "NoeTerraform"
  region  = "us-east-1"
}

provider "aws" {
  profile = "NoeTerraform"
  alias   = "secondary"
  region  = "us-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}