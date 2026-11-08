variable "feature_version" {
  description = "Version of the feature"
  type        = string
}

variable "org" {
  description = "Name of the organization"
  type        = string
}

variable "project" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "Region where to manage the VPC"
  type        = string
}

variable "env" {
  description = "Name of the environment this VPC will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}
