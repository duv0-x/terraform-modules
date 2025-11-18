# Data sources for looking up existing resources or information

# Example: Get current AWS account information
data "aws_caller_identity" "current" {}

# Example: Get current AWS region
data "aws_region" "current" {}

# Example: Get destination region (for replication)
data "aws_region" "destination" {
  count    = var.with_replication ? 1 : 0
  provider = aws.destination
}

# Example: Lookup existing VPC
# data "aws_vpc" "selected" {
#   count = var.vpc_id != "" ? 1 : 0
#   id    = var.vpc_id
# }

# Example: Get availability zones
# data "aws_availability_zones" "available" {
#   state = "available"
# }
