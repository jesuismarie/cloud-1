# Terraform configuration for AWS provider

# AWS provider and backend settings
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4"
    }
  }

  backend "local" {
    path = "./.states/terraform.tfstate"
  }
}

# AWS provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "project-cloud-1"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
