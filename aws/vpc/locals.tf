# Local values for computed configurations
locals {
  # VPC naming
  vpc_name = "${var.vpc_name}-${var.environment}"

  # Default tags applied to all resources
  default_tags = {
    Name        = local.vpc_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "aws-vpc"
  }

  # Merge default tags with user-provided tags
  common_tags = merge(local.default_tags, var.tags)

  # Determine availability zones to use
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  # Calculate number of AZs needed based on subnets
  public_subnet_count  = length(var.public_subnet_cidrs)
  private_subnet_count = length(var.private_subnet_cidrs)
  max_subnet_count     = max(local.public_subnet_count, local.private_subnet_count)

  # Limit AZs to the number of subnets or available AZs, whichever is smaller
  azs_to_use = slice(local.azs, 0, min(local.max_subnet_count, length(local.azs)))

  # NAT Gateway configuration
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.public_subnet_count) : 0

  # VPC Flow Logs configuration
  flow_logs_enabled = var.enable_flow_logs

  # VPC Endpoints
  create_s3_endpoint       = var.enable_s3_endpoint
  create_dynamodb_endpoint = var.enable_dynamodb_endpoint

  # Replication configuration
  has_replication = var.with_replication && var.replication_region != ""

  # Destination region AZs (for replication)
  destination_azs = local.has_replication ? (
    length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.destination[0].names
  ) : []

  destination_azs_to_use = local.has_replication ? slice(
    local.destination_azs,
    0,
    min(local.max_subnet_count, length(local.destination_azs))
  ) : []
}
