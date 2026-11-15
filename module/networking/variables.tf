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
  description = "Region where the CodeArtifact domain will be configured"
  type        = string
}

variable "env" {
  description = "Name of the environment this module will be deployed to (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "cfg" {
  description = "Networking configuration"

  type = object({
    cidr                              = string
    secondary_cidrs                   = list(string)
    enable_dhcp_options               = bool
    dhcp_options_domain_name          = string
    dhcp_options_domain_name_servers  = list(string)
    dhcp_options_ntp_servers          = list(string)
    dhcp_options_netbios_name_servers = list(string)
    dhcp_options_netbios_node_type    = number
    availability_zones                = list(string)
    egress_subnets                    = list(string)
    platform_subnets                  = list(string)
  })
}

variable "flow_logs_cfg" {
  description = "Flow logs configuration"
  type = object({
    enabled        = bool
    retention_days = number
  })
}