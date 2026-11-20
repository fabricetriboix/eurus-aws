variable "feature_version" {
  description = "Version of the feature"
  type        = string
}

variable "org" {
  description = "Name of the organisation"
  type        = string
}

variable "project" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "Region where the PKI subsystem will be deployed"
  type        = string
}

variable "env" {
  description = "Name of the environment this PKI subsystem will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain PKI subsystem logs"
  type        = number
  default     = 30
}
