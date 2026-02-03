# Networking

This document explains how networking works for `eurus-aws`. Please
note that only IPv4 is supported. There is no support for IPv6.

![Networking](eurus-aws-networking.png)

There is one VPC per environment. Each VPC has a primary CIDR
associated with it. It is possible to associate secondary CIDR to the
VPC in order to setup egress to some external networks (typically to
on-prem services).

Each VPC must spread over a minimum of two availability zones in order
to increase availability.

Each VPC has the following subnets (one per availability zone):
  - App subnets: These subnets host the app workloads and have no
    routing to/from outside the VPC. Ingress traffic must come from
    other AWS services such as CloudFront, API Gateways or load
    balancers. Egress traffic must go exclusively through NAT gateways
    located in the egress subnets.
  - Data subnets: These subnets are used to host data stores. Only
    AWS managed data stores (such as RDS) are allowed in these
    subnets.
  - Egress subnets: These subnets hold NAT Gateways to manage egress
    traffic to external networks.

A few notes:
  - Data subnets and egress subnets typically need small CIDR.
  - There is no direct access to the internet to/from the VPC.
  - How the VPC is linked to the on-prem networks is beyond the scope
    of this project.
