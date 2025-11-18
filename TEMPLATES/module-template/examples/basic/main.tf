# Basic usage example for the module

provider "aws" {
  region = "us-east-1"
}

module "example" {
  source = "../.."

  resource_name = "example-resource"
  environment   = "dev"

  tags = {
    Project     = "Example"
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
  }
}

# Outputs from the module
output "resource_id" {
  description = "ID of the created resource"
  value       = module.example.id
}

output "resource_arn" {
  description = "ARN of the created resource"
  value       = module.example.arn
}
