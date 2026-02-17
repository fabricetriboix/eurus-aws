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

variable "secondary_cidrs" {
  description = "Secondary CIDRs for the VPC (typically allocated by the network team to allow access to on-prem services)"
  type        = list(string)
  default     = []
}

variable "enable_dhcp_options" {
  description = "Whether to enable DHCP options for the VPC"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for the DHCP options"
  type        = string
  default     = null
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for the DHCP options"
  type        = list(string)
  default     = null
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for the DHCP options"
  type        = list(string)
  default     = null
}

variable "dhcp_options_netbios_name_servers" {
  description = "NetBIOS name servers for the DHCP options"
  type        = list(string)
  default     = null
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type for the DHCP options"
  type        = number
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones where to deploy the VPC"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 1
    error_message = "At least two availability zones must be listed."
  }
}

variable "egress_subnets" {
  description = "CIDRs for egress subnets (used to manage egress traffic). This list must have the same number of items as `availability_zones`, or be null if no egress is needed."
  type        = list(string)
  default     = null
}
