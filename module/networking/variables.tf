variable "org" {
  description = "Name of the organization"
  type        = string
}

variable "project" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "Region where the CodeArtifact domain will be configured"
  type        = string
}

variable "env" {
  description = "Name of the environment this module will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 8
    error_message = "The `env` variable must be set and must have at most 8 characters."
  }
}

variable "cidr" {
  description = "CIDR for the VPC"
  type        = string
}

variable "secondary_cidrs" {
  description = "Secondary CIDRs for the VPC"
  type        = list(string)
  default     = []
}

variable "enable_dhcp_options" {
  description = "Enable DHCP options"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = null
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "NETBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NETBIOS node type for DHCP options"
  type        = number
  default     = null
}

variable "availability_zones" {
  description = "Availability zones for the VPC"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "The `availability_zones` variable must be set and must have at least 2 items."
  }
}

variable "egress_subnets" {
  description = "Egress subnets for the VPC (optional)"
  type        = list(string)
  default     = null
}

variable "platform_subnets" {
  description = "Platform subnets for the VPC"
  type        = list(string)

  validation {
    condition     = length(var.platform_subnets) == length(var.availability_zones)
    error_message = "The `platform_subnets` variable must be set and must have the same length as the `availability_zones` variable."
  }
}

variable "enable_flow_logs" {
  description = "Enable flow logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention days for flow logs"
  type        = number
  default     = 30
}
