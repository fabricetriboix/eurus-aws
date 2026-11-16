variable "region_cfgs" {
  description = "List of regional configurations"

  type = list(object({
    cidr                              = string
    secondary_cidrs                   = list(string)
    enable_dhcp_options               = bool
    dhcp_options_domain_name          = optional(string)
    dhcp_options_domain_name_servers  = optional(list(string))
    dhcp_options_ntp_servers          = optional(list(string))
    dhcp_options_netbios_name_servers = optional(list(string))
    dhcp_options_netbios_node_type    = optional(number)
    availability_zones                = list(string)
    egress_subnets                    = optional(list(string))
    platform_subnets                  = list(string)
  }))
}

variable "flow_logs_cfg" {
  description = "Flow logs configuration"
  type = object({
    enabled        = bool
    retention_days = number
  })
}
