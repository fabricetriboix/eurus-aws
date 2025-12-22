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

variable "region" {
  description = "The AWS region where to deploy the bootstrap"
  type        = string
}

variable "realm" {
  description = "In which realm to deploy this bootstrap module"
  type        = string

  validation {
    condition     = length(var.realm) > 1
    error_message = "The `realm` must be set."
  }
}

variable "common_tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
}
