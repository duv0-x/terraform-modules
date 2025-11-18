# AWS VPC Terraform Module

## Description

This module creates a complete AWS VPC infrastructure with public and private subnets, NAT Gateways, Internet Gateway, route tables, and optional features like VPC Flow Logs, VPC Endpoints, and multi-region replication.

## Features

- **Complete VPC Setup** - VPC with configurable CIDR block, DNS settings, and instance tenancy
- **Public Subnets** - With Internet Gateway and auto-assign public IP
- **Private Subnets** - With NAT Gateway for outbound internet access
- **Multi-AZ Support** - Automatically distributes subnets across availability zones
- **NAT Gateway Options** - Single NAT Gateway (cost-optimized) or one per AZ (high availability)
- **VPC Flow Logs** - Optional CloudWatch logging for network traffic analysis
- **VPC Endpoints** - Gateway endpoints for S3 and DynamoDB (reduce data transfer costs)
- **Network ACLs** - Optional custom Network ACLs for additional security
- **IPv6 Support** - Optional IPv6 CIDR block assignment
- **Multi-Region Replication** - Create replica VPC in another region for disaster recovery
- **Comprehensive Tagging** - Consistent tagging across all resources

## Usage

### Basic VPC

```hcl
module "vpc" {
  source = "../../aws/vpc"

  vpc_name    = "production-vpc"
  cidr_block  = "10.0.0.0/16"
  environment = "production"

  # Subnets across 3 availability zones
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  # Enable NAT Gateway for private subnets
  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA

  tags = {
    Project    = "MyApp"
    Team       = "Platform"
    CostCenter = "Engineering"
  }
}
```

### Cost-Optimized VPC (Single NAT Gateway)

```hcl
module "vpc_dev" {
  source = "../../aws/vpc"

  vpc_name    = "development-vpc"
  cidr_block  = "10.1.0.0/16"
  environment = "dev"

  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

  # Cost optimization: single NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project = "MyApp"
    Team    = "Development"
  }
}
```

### VPC with Flow Logs and VPC Endpoints

```hcl
module "vpc_with_monitoring" {
  source = "../../aws/vpc"

  vpc_name    = "monitored-vpc"
  cidr_block  = "10.2.0.0/16"
  environment = "production"

  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false

  # Enable VPC Flow Logs
  enable_flow_logs           = true
  flow_logs_retention_days   = 30
  flow_logs_traffic_type     = "ALL"

  # Enable VPC Endpoints (reduce data transfer costs)
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  tags = {
    Project     = "MyApp"
    Team        = "Platform"
    Compliance  = "Required"
  }
}
```

### Multi-Region VPC with Replication

```hcl
# Primary region provider
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# DR region provider
provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "vpc_with_dr" {
  source = "../../aws/vpc"

  vpc_name    = "multi-region-vpc"
  cidr_block  = "10.3.0.0/16"
  environment = "production"

  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
  private_subnet_cidrs = ["10.3.10.0/24", "10.3.11.0/24", "10.3.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  # Enable multi-region replication
  with_replication   = true
  replication_region = "us-west-2"

  providers = {
    aws             = aws.primary
    aws.destination = aws.dr
  }

  tags = {
    Project = "MyApp"
    Team    = "Platform"
    DR      = "Enabled"
  }
}

# Access replica VPC outputs
output "primary_vpc_id" {
  value = module.vpc_with_dr.vpc_id
}

output "replica_vpc_id" {
  value = module.vpc_with_dr.replica_vpc_id
}
```

### VPC with Custom Availability Zones

```hcl
module "vpc_custom_azs" {
  source = "../../aws/vpc"

  vpc_name    = "custom-az-vpc"
  cidr_block  = "10.4.0.0/16"
  environment = "production"

  # Specify exact AZs to use
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.4.1.0/24", "10.4.2.0/24"]
  private_subnet_cidrs = ["10.4.10.0/24", "10.4.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Project = "MyApp"
  }
}
```

### Public-Only VPC (No Private Subnets)

```hcl
module "vpc_public_only" {
  source = "../../aws/vpc"

  vpc_name    = "public-vpc"
  cidr_block  = "10.5.0.0/16"
  environment = "dev"

  # Only public subnets, no private subnets
  public_subnet_cidrs = ["10.5.1.0/24", "10.5.2.0/24"]

  # No NAT Gateway needed
  enable_nat_gateway = false

  tags = {
    Project = "PublicApp"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| aws.destination | >= 5.0 |

## Resources

This module creates the following resources:

| Resource Type | Description |
|---------------|-------------|
| aws_vpc | Primary VPC and optional replica VPC |
| aws_subnet | Public and private subnets in multiple AZs |
| aws_internet_gateway | Internet Gateway for public subnet internet access |
| aws_nat_gateway | NAT Gateways for private subnet outbound internet |
| aws_eip | Elastic IPs for NAT Gateways |
| aws_route_table | Route tables for public and private subnets |
| aws_route | Routes for internet and NAT gateway traffic |
| aws_route_table_association | Subnet to route table associations |
| aws_vpc_endpoint | Optional S3 and DynamoDB gateway endpoints |
| aws_flow_log | Optional VPC Flow Logs |
| aws_cloudwatch_log_group | Log group for VPC Flow Logs |
| aws_iam_role | IAM role for VPC Flow Logs |
| aws_network_acl | Optional custom Network ACLs |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name of the VPC | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC | `string` | n/a | yes |
| environment | Environment name (dev, staging, production) | `string` | `"dev"` | no |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in the VPC | `bool` | `true` | no |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | `[]` | no |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | `[]` | no |
| availability_zones | List of AZs for subnet distribution | `list(string)` | `[]` | no |
| single_nat_gateway | Use single NAT Gateway for cost optimization | `bool` | `false` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `false` | no |
| flow_logs_retention_days | Days to retain VPC Flow Logs | `number` | `7` | no |
| flow_logs_traffic_type | Type of traffic to capture (ACCEPT/REJECT/ALL) | `string` | `"ALL"` | no |
| enable_network_acls | Enable custom Network ACLs | `bool` | `false` | no |
| enable_s3_endpoint | Enable S3 VPC Endpoint | `bool` | `false` | no |
| enable_dynamodb_endpoint | Enable DynamoDB VPC Endpoint | `bool` | `false` | no |
| with_replication | Create replica VPC in another region | `bool` | `false` | no |
| replication_region | AWS region for VPC replication | `string` | `""` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |
| instance_tenancy | Instance tenancy (default/dedicated) | `string` | `"default"` | no |
| enable_ipv6 | Enable IPv6 support | `bool` | `false` | no |
| map_public_ip_on_launch | Auto-assign public IPs in public subnets | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| vpc_default_security_group_id | The ID of the default security group |
| internet_gateway_id | The ID of the Internet Gateway |
| public_subnet_ids | List of IDs of public subnets |
| public_subnet_cidr_blocks | List of CIDR blocks of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| private_subnet_cidr_blocks | List of CIDR blocks of private subnets |
| nat_gateway_ids | List of IDs of NAT Gateways |
| nat_gateway_public_ips | List of public IPs of NAT Gateways |
| public_route_table_id | The ID of the public route table |
| private_route_table_ids | List of IDs of private route tables |
| availability_zones | List of availability zones used |
| flow_logs_log_group_name | CloudWatch Log Group name for Flow Logs |
| s3_vpc_endpoint_id | The ID of the S3 VPC Endpoint |
| dynamodb_vpc_endpoint_id | The ID of the DynamoDB VPC Endpoint |
| replica_vpc_id | The ID of the replica VPC |
| replica_public_subnet_ids | List of IDs of replica public subnets |
| replica_private_subnet_ids | List of IDs of replica private subnets |

## Examples

See the [examples](./examples) directory for complete example configurations:

- [basic](./examples/basic) - Simple VPC with public and private subnets
- [with-replication](./examples/with-replication) - Multi-region VPC setup
- [cost-optimized](./examples/cost-optimized) - Development VPC with single NAT
- [full-featured](./examples/full-featured) - Production VPC with all features

## Architecture

### Basic VPC Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Internet Gateway                       │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                       │
│  ┌──────────────────────┴──────────────────────────────────┐   │
│  │              Public Route Table (0.0.0.0/0 → IGW)       │   │
│  └─┬─────────────────────────────────────────────────────┬─┘   │
│    │                                                     │       │
│  ┌─┴─────────────────┐                   ┌──────────────┴────┐ │
│  │ Public Subnet 1   │                   │ Public Subnet 2   │ │
│  │ (10.0.1.0/24)     │                   │ (10.0.2.0/24)     │ │
│  │     us-east-1a    │                   │    us-east-1b     │ │
│  │  ┌──────────────┐ │                   │  ┌──────────────┐ │ │
│  │  │ NAT Gateway  │ │                   │  │ NAT Gateway  │ │ │
│  │  └──────┬───────┘ │                   │  └──────┬───────┘ │ │
│  └─────────┼─────────┘                   └─────────┼─────────┘ │
│            │                                       │             │
│  ┌─────────┴─────────┐                   ┌────────┴──────────┐ │
│  │ Private RT        │                   │ Private RT        │ │
│  │ (0.0.0.0/0 → NAT) │                   │ (0.0.0.0/0 → NAT) │ │
│  └─────────┬─────────┘                   └────────┬──────────┘ │
│            │                                      │             │
│  ┌─────────┴─────────┐                   ┌───────┴───────────┐ │
│  │ Private Subnet 1  │                   │ Private Subnet 2  │ │
│  │ (10.0.10.0/24)    │                   │ (10.0.11.0/24)    │ │
│  │    us-east-1a     │                   │    us-east-1b     │ │
│  └───────────────────┘                   └───────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Best Practices

1. **CIDR Planning**: Plan your CIDR blocks carefully to avoid overlaps with other VPCs or on-premises networks
2. **Multi-AZ**: Always use at least 2 availability zones for production workloads
3. **NAT Gateway HA**: Use `single_nat_gateway = false` for production (one NAT per AZ)
4. **Cost Optimization**: Use `single_nat_gateway = true` for dev/test environments
5. **VPC Endpoints**: Enable S3 and DynamoDB endpoints to reduce data transfer costs
6. **Flow Logs**: Enable Flow Logs for production VPCs for security and troubleshooting
7. **Tagging**: Use comprehensive tags for cost allocation and resource management
8. **Subnet Sizing**: Leave room for growth - don't use all available IPs in your CIDR
9. **Private Subnets**: Place application workloads in private subnets for security
10. **Public Subnets**: Use public subnets only for load balancers and bastion hosts

## Cost Considerations

- **NAT Gateway**: Each NAT Gateway costs ~$0.045/hour + data processing charges
  - Single NAT: ~$32/month
  - Multi-AZ (3 NATs): ~$97/month
- **VPC Flow Logs**: CloudWatch Logs storage and ingestion costs
- **VPC Endpoints**: Gateway endpoints (S3, DynamoDB) are free, interface endpoints have hourly charges
- **Elastic IPs**: Free when attached to running instances, $0.005/hour when unattached

## Security Considerations

- Private subnets have no direct internet access (outbound only through NAT)
- Use security groups and NACLs for defense in depth
- Enable VPC Flow Logs for audit and compliance
- Use VPC endpoints to keep traffic within AWS network
- Implement least-privilege access with IAM policies
- Consider using AWS PrivateLink for service access

## Troubleshooting

### Issue: Resources in private subnet can't access the internet

**Solution**: Ensure `enable_nat_gateway = true` and verify route table associations

### Issue: VPC creation fails with CIDR overlap

**Solution**: Check for CIDR conflicts with existing VPCs or peering connections

### Issue: Flow Logs not appearing in CloudWatch

**Solution**: Verify IAM role permissions and check CloudWatch Logs retention settings

### Issue: High NAT Gateway costs

**Solution**: Consider using a single NAT Gateway for dev/test or implement VPC endpoints for AWS services

## License

Internal use only.
