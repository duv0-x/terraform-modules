# Multi-region VPC with disaster recovery replication

# Primary region provider (us-east-1)
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# Disaster recovery region provider (us-west-2)
provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "vpc_with_dr" {
  source = "../.."

  vpc_name    = "multi-region-vpc"
  cidr_block  = "10.3.0.0/16"
  environment = "production"

  # Subnets across 3 availability zones
  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
  private_subnet_cidrs = ["10.3.10.0/24", "10.3.11.0/24", "10.3.12.0/24"]

  # High availability configuration
  enable_nat_gateway = true
  single_nat_gateway = false

  # Enable replication to DR region
  with_replication   = true
  replication_region = "us-west-2"

  # Enable monitoring
  enable_flow_logs         = true
  flow_logs_retention_days = 30

  # Enable VPC endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  providers = {
    aws             = aws.primary
    aws.destination = aws.dr
  }

  tags = {
    Project         = "Production"
    Team            = "Platform"
    DR              = "Enabled"
    BackupRegion    = "us-west-2"
    CriticalityTier = "Tier1"
  }
}

# Primary Region Outputs
output "primary_vpc_id" {
  description = "Primary VPC ID (us-east-1)"
  value       = module.vpc_with_dr.vpc_id
}

output "primary_vpc_cidr" {
  description = "Primary VPC CIDR block"
  value       = module.vpc_with_dr.vpc_cidr_block
}

output "primary_public_subnet_ids" {
  description = "Primary region public subnet IDs"
  value       = module.vpc_with_dr.public_subnet_ids
}

output "primary_private_subnet_ids" {
  description = "Primary region private subnet IDs"
  value       = module.vpc_with_dr.private_subnet_ids
}

output "primary_nat_gateway_ips" {
  description = "Primary region NAT Gateway public IPs"
  value       = module.vpc_with_dr.nat_gateway_public_ips
}

# DR Region Outputs
output "dr_vpc_id" {
  description = "DR VPC ID (us-west-2)"
  value       = module.vpc_with_dr.replica_vpc_id
}

output "dr_vpc_cidr" {
  description = "DR VPC CIDR block"
  value       = module.vpc_with_dr.replica_vpc_cidr_block
}

output "dr_public_subnet_ids" {
  description = "DR region public subnet IDs"
  value       = module.vpc_with_dr.replica_public_subnet_ids
}

output "dr_private_subnet_ids" {
  description = "DR region private subnet IDs"
  value       = module.vpc_with_dr.replica_private_subnet_ids
}

output "dr_nat_gateway_ips" {
  description = "DR region NAT Gateway public IPs"
  value       = module.vpc_with_dr.replica_nat_gateway_public_ips
}

# Summary
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    primary_region = "us-east-1"
    dr_region      = "us-west-2"
    vpc_cidr       = "10.3.0.0/16"
    azs_per_region = 3
    nat_gw_per_az  = true
  }
}
