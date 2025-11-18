# Multi-region replication example

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# Destination region provider for replication
provider "aws" {
  alias  = "destination"
  region = "us-west-2"
}

module "example_with_replication" {
  source = "../.."

  resource_name      = "replicated-resource"
  environment        = "production"
  with_replication   = true
  replication_region = "us-west-2"

  providers = {
    aws             = aws.primary
    aws.destination = aws.destination
  }

  tags = {
    Project         = "Example"
    Owner           = "DevOps Team"
    CostCenter      = "Engineering"
    ReplicationMode = "active"
  }
}

# Outputs
output "primary_resource_id" {
  description = "ID of the primary resource"
  value       = module.example_with_replication.id
}

output "primary_resource_arn" {
  description = "ARN of the primary resource"
  value       = module.example_with_replication.arn
}

output "replica_resource_id" {
  description = "ID of the replica resource"
  value       = module.example_with_replication.replica_id
}

output "replica_resource_arn" {
  description = "ARN of the replica resource"
  value       = module.example_with_replication.replica_arn
}
