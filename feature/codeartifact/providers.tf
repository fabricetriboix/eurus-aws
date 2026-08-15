terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
  }
}

locals {
  default_tags = {
    FeatureSource  = "feature/codeartifact"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}

provider "aws" {
  default_tags {
    tags = local.default_tags
  }
}

provider "awscc" {
}
