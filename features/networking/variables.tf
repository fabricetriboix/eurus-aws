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

variable "public_subnet_bits" {
  description = "Number of bits to use for the public subnet CIDRs"
  type        = number
  default     = 8

  validation {
    condition     = var.public_subnet_bits > 0
    error_message = "The number of bits for public subnet CIDRs must be at least 1."
  }
}

variable "private_subnet_bits" {
  description = "Number of bits to use for the private subnet CIDRs"
  type        = number
  default     = 8

  validation {
    condition     = var.private_subnet_bits > 0
    error_message = "The number of bits for private subnet CIDRs must be at least 1."
  }
}

variable "db_subnet_bits" {
  description = "Number of bits to use for the database subnet CIDRs"
  type        = number
  default     = 8

  validation {
    condition     = var.db_subnet_bits > 0
    error_message = "The number of bits for database subnet CIDRs must be at least 1."
  }
}

variable "internal_subnet_bits" {
  description = "Number of bits to use for the internal subnet CIDRs. Internal subnets are routable only within the VPC itself."
  type        = number
  default     = 8

  validation {
    condition     = var.internal_subnet_bits > 0
    error_message = "The number of bits for internal subnet CIDRs must be at least 1."
  }
}
