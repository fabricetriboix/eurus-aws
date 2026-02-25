variable "org" {
  description = "Organisation this projects belongs to"
  type        = string

  validation {
    condition     = length(var.org) > 1
    error_message = "The `org` variable must be set."
  }
}

variable "project" {
  description = "The project for this bootstrap"
  type        = string

  validation {
    condition     = length(var.project) > 1
    error_message = "The `project` variable must be set."
  }
}

variable "realm" {
  description = "In which realm to deploy this bootstrap module (typically nonprod or prod)"
  type        = string

  validation {
    condition     = length(var.realm) > 1
    error_message = "The `realm` must be set."
  }
}

variable "account_id" {
  description = "The account ID"
  type        = string

  validation {
    condition     = length(var.account_id) > 1
    error_message = "The `account_id` must be set."
  }
}

variable "account_type" {
  description = "The account type (common or app) "
  type        = string

  validation {
    condition     = var.account_type == "common" || var.account_type == "app"
    error_message = "The `account_type` must be either 'common' or 'app'."
  }
}

variable "region" {
  description = "The region to deploy the bootstrap module to"
  type        = string

  validation {
    condition     = length(var.region) > 1
    error_message = "The `region` must be set."
  }
}