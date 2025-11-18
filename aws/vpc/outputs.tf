################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block of the VPC"
  value       = var.enable_ipv6 ? aws_vpc.this.ipv6_cidr_block : null
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with the VPC"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

################################################################################
# Internet Gateway Outputs
################################################################################

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = local.public_subnet_count > 0 ? aws_internet_gateway.this[0].id : null
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway"
  value       = local.public_subnet_count > 0 ? aws_internet_gateway.this[0].arn : null
}

################################################################################
# Subnet Outputs
################################################################################

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

################################################################################
# NAT Gateway Outputs
################################################################################

output "nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of allocation IDs of Elastic IPs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

################################################################################
# Route Table Outputs
################################################################################

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = local.public_subnet_count > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

################################################################################
# VPC Flow Logs Outputs
################################################################################

output "flow_logs_log_group_name" {
  description = "The name of the CloudWatch Log Group for VPC Flow Logs"
  value       = local.flow_logs_enabled ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = local.flow_logs_enabled ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "flow_logs_iam_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs"
  value       = local.flow_logs_enabled ? aws_iam_role.flow_logs[0].arn : null
}

################################################################################
# VPC Endpoint Outputs
################################################################################

output "s3_vpc_endpoint_id" {
  description = "The ID of the S3 VPC Endpoint"
  value       = local.create_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_vpc_endpoint_id" {
  description = "The ID of the DynamoDB VPC Endpoint"
  value       = local.create_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

################################################################################
# Network ACL Outputs
################################################################################

output "public_network_acl_id" {
  description = "The ID of the public Network ACL"
  value       = var.enable_network_acls && local.public_subnet_count > 0 ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "The ID of the private Network ACL"
  value       = var.enable_network_acls && local.private_subnet_count > 0 ? aws_network_acl.private[0].id : null
}

################################################################################
# Availability Zones Output
################################################################################

output "availability_zones" {
  description = "List of availability zones used for subnets"
  value       = local.azs_to_use
}

################################################################################
# Replica VPC Outputs
################################################################################

output "replica_vpc_id" {
  description = "The ID of the replica VPC (if replication is enabled)"
  value       = local.has_replication ? aws_vpc.replica[0].id : null
}

output "replica_vpc_arn" {
  description = "The ARN of the replica VPC (if replication is enabled)"
  value       = local.has_replication ? aws_vpc.replica[0].arn : null
}

output "replica_vpc_cidr_block" {
  description = "The CIDR block of the replica VPC (if replication is enabled)"
  value       = local.has_replication ? aws_vpc.replica[0].cidr_block : null
}

output "replica_public_subnet_ids" {
  description = "List of IDs of replica public subnets (if replication is enabled)"
  value       = local.has_replication ? aws_subnet.replica_public[*].id : []
}

output "replica_private_subnet_ids" {
  description = "List of IDs of replica private subnets (if replication is enabled)"
  value       = local.has_replication ? aws_subnet.replica_private[*].id : []
}

output "replica_nat_gateway_ids" {
  description = "List of IDs of replica NAT Gateways (if replication is enabled)"
  value       = local.has_replication ? aws_nat_gateway.replica[*].id : []
}

output "replica_nat_gateway_public_ips" {
  description = "List of public IPs of replica NAT Gateways (if replication is enabled)"
  value       = local.has_replication ? aws_eip.replica_nat[*].public_ip : []
}

output "replica_internet_gateway_id" {
  description = "The ID of the replica Internet Gateway (if replication is enabled)"
  value       = local.has_replication && local.public_subnet_count > 0 ? aws_internet_gateway.replica[0].id : null
}

################################################################################
# Useful Combined Outputs
################################################################################

output "vpc" {
  description = "Complete VPC resource object"
  value       = aws_vpc.this
}

output "subnets" {
  description = "Map of all subnets (public and private)"
  value = {
    public  = aws_subnet.public
    private = aws_subnet.private
  }
}
