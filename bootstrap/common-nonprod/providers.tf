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
      Realm      = "nonprod"
      Source     = "bootstrap/common-nonprod"
      Tenant     = "Platform"
      CostCenter = "1001"
    }
  }
}
