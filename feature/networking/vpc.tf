# VPC and subnets

resource "aws_vpc" "this" {
  cidr_block                           = var.cidr
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = length(var.secondary_cidrs)

  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidrs[count.index]
}

resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

resource "aws_subnet" "egress" {
  count = local.egress_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.egress_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.env}-egress-${var.availability_zones[count.index]}"
  }
}

// Route tables

resource "aws_route_table" "egress" {
  count = local.egress_subnet_count

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.env}-egress-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "egress" {
  count = local.egress_subnet_count

  subnet_id      = aws_subnet.egress[count.index].id
  route_table_id = aws_route_table.egress[count.index].id
}
