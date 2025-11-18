# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get available availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"

  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get destination region information (for replication)
data "aws_region" "destination" {
  count    = var.with_replication ? 1 : 0
  provider = aws.destination
}

# Get available availability zones in destination region (for replication)
data "aws_availability_zones" "destination" {
  count    = var.with_replication ? 1 : 0
  provider = aws.destination
  state    = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
