variable "org" {
  description = "Organisation this projects belongs to"
  type        = string

  validation {
    condition     = length(var.org) > 1
    error_message = "The `org` variable must be set."
  }
}

variable "project" {
  description = "The project name of the platform to bootstrap"
  type        = string

  validation {
    condition     = length(var.project) > 1
    error_message = "The `project` variable must be set."
  }
}

variable "region" {
  description = "The region where the platform to bootstrap is located"
  type        = string

  validation {
    condition     = length(var.region) > 1
    error_message = "The `region` variable must be set."
  }
}

variable "realm" {
  description = "Realm the AWS account belongs to (typically `nonprod` or `prod`)"
  type        = string

  validation {
    condition     = length(var.realm) > 1
    error_message = "The `realm` variable must be set."
  }
}

variable "account_id" {
  description = "ID of the AWS account to bootstrap"
  type        = string

  validation {
    condition     = length(var.account_id) > 1
    error_message = "The `account_id` variable must be set."
  }
}

variable "account_type" {
  description = "The account type of the AWS account to bootstrap (must be either `common` or `app`)"
  type        = string

  validation {
    condition     = var.account_type == "common" || var.account_type == "app"
    error_message = "The `account_type` variable must be either `common` or `app`."
  }
}
