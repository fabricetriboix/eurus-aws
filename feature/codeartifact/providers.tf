terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.97.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.default_tags
  }
}

provider "awscc" {
  region = var.region
}
