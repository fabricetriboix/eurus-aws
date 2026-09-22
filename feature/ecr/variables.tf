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
  description = "Region where to manage the ECR registry"
  type        = string
}

variable "env" {
  description = "Name of the environment this ECR registry will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "source_account_ids" {
  description = "List of IDs of AWS accounts that will be allowed to create repositories and push images into this ECR registry"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.source_account_ids : length(id) == 12])
    error_message = "The `source_account_ids` variable must contain account IDs with 12 characters."
  }
}

variable "pull_account_ids" {
  description = "List of IDs of AWS accounts that will be allowed to pull images from this ECR registry"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.pull_account_ids : length(id) == 12])
    error_message = "The `pull_account_ids` variable must contain account IDs with 12 characters."
  }
}

variable "retention_in_days" {
  description = "How many days to keep container images stored in ECR; set to 0 to keep forever."
  type        = number

  validation {
    condition     = var.retention_in_days >= 0
    error_message = "The `retention_in_days` variable must be set and must be greater than or equal to 0."
  }
}
