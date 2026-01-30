variable "env" {
  description = "Name of the environment this VPC will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "cidr" {
  description = "CIDR for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones where to deploy the VPC"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 1
    error_message = "At least two availability zones must be listed."
  }
}

variable "public_subnets" {
  description = "CIDRs for public subnets (can receive internet traffic). This list must have the same number of items than `availability_zones`, or be null."
  type        = list(string)
  default     = null
}

variable "private_subnets" {
  description = "CIDRs for private subnets (can't receive internet traffic). This list must have the same number of items than `availability_zones`, or be null."
  type        = list(string)
  default     = null
}

variable "db_subnets" {
  description = "CIDRs for database subnets (used to host databases). This list must have the same number of items than `availability_zones`, or be null."
  type        = list(string)
  default     = null
}

variable "internal_subnets" {
  description = "CIDRs for internal subnets (no routing outside the VPC). This list must have the same number of items than `availability_zones`, or be null."
  type        = list(string)
  default     = null
}
