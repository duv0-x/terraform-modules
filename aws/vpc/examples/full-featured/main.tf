# Full-featured production VPC with all options enabled

provider "aws" {
  region = "us-east-1"
}

module "vpc_production" {
  source = "../.."

  vpc_name    = "production-vpc"
  cidr_block  = "10.2.0.0/16"
  environment = "production"

  # Subnets across 3 availability zones for HA
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]

  # High availability: one NAT Gateway per AZ
  enable_nat_gateway = true
  single_nat_gateway = false

  # Enable VPC Flow Logs for security and compliance
  enable_flow_logs         = true
  flow_logs_retention_days = 30
  flow_logs_traffic_type   = "ALL"

  # Enable VPC Endpoints to reduce data transfer costs
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Enable custom Network ACLs for additional security
  enable_network_acls = true

  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Auto-assign public IPs in public subnets
  map_public_ip_on_launch = true

  tags = {
    Project     = "Production"
    Team        = "Platform"
    CostCenter  = "Engineering"
    Compliance  = "Required"
    Backup      = "Daily"
    Environment = "Production"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc_production.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc_production.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc_production.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc_production.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc_production.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc_production.nat_gateway_public_ips
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc_production.availability_zones
}

output "flow_logs_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = module.vpc_production.flow_logs_log_group_name
}

output "s3_vpc_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = module.vpc_production.s3_vpc_endpoint_id
}

output "dynamodb_vpc_endpoint_id" {
  description = "DynamoDB VPC Endpoint ID"
  value       = module.vpc_production.dynamodb_vpc_endpoint_id
}
