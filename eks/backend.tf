terraform {
  required_version = "~> 1.9.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
  backend "s3" {
    bucket         = "my-eks-bucket-state-file"
    region         = "us-east-1"
    key            = "eks/terraform.tfstate"
    dynamodb_table = "terraform-state-table"
    encrypt        = true   # Enable encryption for secure state files
  }
}

provider "aws" {
  region  = var.aws-region
}
