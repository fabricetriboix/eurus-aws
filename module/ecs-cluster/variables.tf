variable "org" {
  description = "The organization name"
  type        = string
}

variable "project" {
  description = "The project name"
  type        = string
}

variable "env" {
  description = "Name of the environment this ECS cluster will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "region" {
  description = "The region where the ECS cluster is located"
  type        = string
}

variable "cluster_name_suffix" {
  description = "The suffix of the ECS cluster name"
  type        = string

  validation {
    condition     = length(var.cluster_name_suffix) > 1 && length(var.cluster_name_suffix) <= 16
    error_message = "The `cluster_name_suffix` variable must be set and must have at most 16 characters and at least 2 characters."
  }
}

variable "log_retention_days" {
  description = "The number of days to retain the logs of the ECS cluster"
  type        = number
  default     = 30
}

variable "extra_tags" {
  description = "Extra tags to add to the ECS cluster"
  type        = map(string)
  default     = {}
}
