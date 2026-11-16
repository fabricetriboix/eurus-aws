# VPC

resource "aws_vpc" "this" {
  cidr_block                           = var.cfg.cidr
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true

  tags = {
    Name = "${var.org}-${var.project}-${var.env}"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = try(length(var.cfg.secondary_cidrs), 0)

  vpc_id     = aws_vpc.this.id
  cidr_block = var.cfg.secondary_cidrs[count.index]
}

resource "aws_vpc_dhcp_options" "this" {
  count = var.cfg.enable_dhcp_options ? 1 : 0

  domain_name          = var.cfg.dhcp_options_domain_name
  domain_name_servers  = var.cfg.dhcp_options_domain_name_servers
  ntp_servers          = var.cfg.dhcp_options_ntp_servers
  netbios_name_servers = var.cfg.dhcp_options_netbios_name_servers
  netbios_node_type    = var.cfg.dhcp_options_netbios_node_type

  tags = {
    Name = "${var.org}-${var.project}-${var.env}-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.cfg.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# Egress subnets & routing tables

check "egress_length_matches_az_count" {
  assert {
    condition     = var.cfg.egress_subnets == null || (length(var.cfg.egress_subnets) == length(var.cfg.availability_zones))
    error_message = "`egress_subnets` and `availability_zones` must have the same number of elements."
  }
}

resource "aws_subnet" "egress" {
  count = try(length(var.cfg.egress_subnets), 0)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.cfg.egress_subnets[count.index]
  availability_zone = var.cfg.availability_zones[count.index]

  # Subnets in a secondary CIDR must be destroyed before that association is
  # removed. Without this, OpenTofu may disassociate the block while subnets
  # still exist.
  depends_on = [aws_vpc_ipv4_cidr_block_association.this]

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-egress-${var.cfg.availability_zones[count.index]}"
    Purpose = "Egress subnet for AZ ${var.cfg.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "egress" {
  count = try(length(var.cfg.egress_subnets), 0)

  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-egress-${var.cfg.availability_zones[count.index]}"
    Purpose = "Egress route table for AZ ${var.cfg.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "egress" {
  count = try(length(var.cfg.egress_subnets), 0)

  subnet_id      = aws_subnet.egress[count.index].id
  route_table_id = aws_route_table.egress[count.index].id
}

# Platform subnets & routing tables

check "platform_length_matches_az_count" {
  assert {
    condition     = length(var.cfg.platform_subnets) == length(var.cfg.availability_zones)
    error_message = "`platform_subnets` and `availability_zones` must have the same number of elements."
  }
}

resource "aws_subnet" "platform" {
  count = length(var.cfg.platform_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.cfg.platform_subnets[count.index]
  availability_zone = var.cfg.availability_zones[count.index]

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-platform-${var.cfg.availability_zones[count.index]}"
    Purpose = "Platform subnet for AZ ${var.cfg.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "platform" {
  count = length(var.cfg.platform_subnets)

  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-platform-${var.cfg.availability_zones[count.index]}"
    Purpose = "Platform subnet for AZ ${var.cfg.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "platform" {
  count = length(var.cfg.platform_subnets)

  subnet_id      = aws_subnet.platform[count.index].id
  route_table_id = aws_route_table.platform[count.index].id
}
