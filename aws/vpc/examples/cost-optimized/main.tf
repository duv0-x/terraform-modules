# Cost-optimized VPC example with single NAT Gateway

provider "aws" {
  region = "us-east-1"
}

module "vpc_cost_optimized" {
  source = "../.."

  vpc_name    = "dev-vpc"
  cidr_block  = "10.1.0.0/16"
  environment = "dev"

  # Subnets across 2 availability zones
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

  # Cost optimization: single NAT Gateway
  # Saves ~$65/month compared to multi-AZ NAT
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project     = "Development"
    Environment = "Dev"
    CostCenter  = "Engineering"
  }
}

# Outputs
output "vpc_id" {
  value = module.vpc_cost_optimized.vpc_id
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways (should be 1)"
  value       = length(module.vpc_cost_optimized.nat_gateway_ids)
}

output "monthly_nat_cost_estimate" {
  description = "Estimated monthly NAT Gateway cost (USD)"
  value       = "~$32/month (1 NAT Gateway)"
}
