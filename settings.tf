terraform {
  required_version = ">= 1.3.2"
  
  backend "s3" {
    bucket = "wiz-project"
    key    = "terraform"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

