# Networking

This section explains how networking works for `eurus-aws`. Please
note that only IPv4 is supported. There is no support for IPv6.

![Networking](eurus-aws-networking.png)

There is one VPC per environment. Each VPC has a primary CIDR
associated with it. It is possible to associate secondary CIDR to the
VPC in order to setup egress to some external networks (typically to
on-prem services).

Each VPC must spread over a minimum of two availability zones in order
to increase availability.

Each VPC has the following subnets:
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
  - Data subnets and egress subnets typically need small CIDRs.
  - There is no direct access to the internet to/from the VPC.
  - How the VPC is linked to the on-prem networks is beyond the scope
    of this project.

Since this project is geared towards small and medium sized
businesses, it is quite uncommon such businesses have on-prem
workloads/databases to connect to. So `eurus-aws` will provide an
egress solution, but it will be shared between tenants and thus may be
subject to the "noisy neighbour" problem. This is the tradeoff in
order to keep cost low, given that the egress solution is based on NAT
Gateways which aren't cheap.

# Tenant segregation and onboarding

Tenant workloads must run in a closes subnet (i.e. with no direct
access to/from anything outside the VPC). In order to increase
security and minimise the chances of one tenant exhausting the IP
address pool of such a subnet, there will be one app subnet per tenant
per availablity zone.

On the database side of things, AWS provides an excellent serverless
SQL database service: Aurora Serverless V2. It scales from almost 0 to
almost infinity. For NoSQL, AWS provides DynamoDB which is extremely
fast and scale again from 0 to infinity. The problem with DynamoDB is
that it is proprietary and quite rudimentary, so moving from MongoDB
and suchlike to DynamoDB would be a pain. AWS does provide DocumentDB
which is 100% compatible with MongoDB, but it is not truly serverless.

There is also a question of apportioning costs to tenants according to
how much of the database they use. Using a single database instance
shared amongst all tenants will make it difficult to apportion costs
effectively. On top of that, it exposes tenants to the "noisy
neighbour" problem, where a single tenant can crowd out the other
tenants and starve them of database access.

Overall, I decided to segregate tenant's databases. Most applications
still use SQL databases, and Aurora Serverless V2 does an excellent
job here for Postgres and MySQL. If a tenant has other requirements,
such as Redis, MongoDB, DB2 or Oracle, they will have to pay extra for
a dedicated database instance/cluster.

The resources that are dedicated to a given tenant will be created
when this specific tenant is onboarded (as opposed to the platform
itself being updated). These resources are:
  - Dedicated app subnets
  - Dedicated database subnets
