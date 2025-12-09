# eurus-aws

Multi-tenant platform built using AWS managed services.

## How to use

Please refer to [the "How to use" document](docs/How to use.md).

## Specifications

This platform uses only AWS services. Tenant apps are run in ECS using
Fargate.

Features:
  - One AWS account per environment
  - One AWS account for common services for all non-prod environments
  - One AWS account for common services for all prod environments
  - Containerised stateless workloads run in ECS + ALB
  - Container images managed with ECR
  - Database services provided by RDS, ElastiCache, DocumentDB, and
    other AWS managed services
  - Object-based storage provided by S3
  - Ingress provided by CloudFront and/or API Gateway
  - Egress provided by NAT Gateways [ref](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-scenarios.html#private-nat-allowed-range)
  - Observability:
      * Logging: provided by CloudWatch Logs
      * Metrics: provided by CloudWatch Metrics
      * Distributed tracing: AWS X-Ray
      * Visualisation: CloudWatch Dashboards
      * Alerting: CloudWatch Alarms
  - High availability achieved using multiple availability zones with
    failovers for each components of the architecture
  - Workload scaling provided by AWS Application Auto Scaling
  - Disaster recovery (RPO = RTO = 4 hours)
  - Costs allocated to tenants using tags
  - Secrets management done using AWS Secrets Manager
  - DNS with Route53
  - TLS with Amazon Certificate Manager

Out of scope:
  - Stateful workloads (AWS provides plenty of stateful services, such
    as RDS and S3, so it is very unlikely a generic stateful solution
    would be required)
  - Multi-region setup

Must exists prior:
  - An AWS Organization with:
    * a management account
    * one account per environment
    * one account for non-prod common services
    * one account for prod common services
  - An IAM role with enough permissions to deploy everything in these
    stacks using OpenTofu
