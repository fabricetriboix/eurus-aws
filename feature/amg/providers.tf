terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      FeatureSource  = "feature/amg"
      FeatureVersion = var.feature_version
    }
  }
}
