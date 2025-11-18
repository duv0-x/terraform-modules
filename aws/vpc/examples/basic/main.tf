# Basic VPC example with public and private subnets

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../.."

  vpc_name    = "example-vpc"
  cidr_block  = "10.0.0.0/16"
  environment = "dev"

  # Subnets across 2 availability zones
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  # Enable NAT Gateway for private subnets
  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Project = "Example"
    Owner   = "DevOps Team"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_gateway_public_ips
}
