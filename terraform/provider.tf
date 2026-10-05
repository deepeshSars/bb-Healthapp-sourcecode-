terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bbhealthapp-terraform-state-deepesh"
    key            = "bbhealthapp/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "bbhealthapp-terraform-lock"
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}
