terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.8.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.default_tags
  }
}
