################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # IPv6 support
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    local.common_tags,
    {
      Name = local.vpc_name
    }
  )
}

################################################################################
# IPv6 CIDR Block Association (if enabled)
################################################################################

resource "aws_vpc_ipv6_cidr_block_association" "this" {
  count = var.enable_ipv6 ? 1 : 0

  vpc_id = aws_vpc.this.id
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-igw"
    }
  )
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs_to_use[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-${local.azs_to_use[count.index]}"
      Type = "public"
    }
  )
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs_to_use[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-${local.azs_to_use[count.index]}"
      Type = "private"
    }
  )
}

################################################################################
# Elastic IPs for NAT Gateways
################################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# NAT Gateways
################################################################################

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat-${local.azs_to_use[var.single_nat_gateway ? 0 : count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Public Route Table
################################################################################

resource "aws_route_table" "public" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-rt"
      Type = "public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = local.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# Private Route Tables
################################################################################

resource "aws_route_table" "private" {
  count = local.private_subnet_count

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-rt-${local.azs_to_use[count.index]}"
      Type = "private"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? local.private_subnet_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = local.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

################################################################################
# VPC Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = local.flow_logs_enabled ? 1 : 0

  name              = "/aws/vpc/flowlogs/${local.vpc_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs"
    }
  )
}

resource "aws_iam_role" "flow_logs" {
  count = local.flow_logs_enabled ? 1 : 0

  name = "${local.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.flow_logs_enabled ? 1 : 0

  name = "${local.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = local.flow_logs_enabled ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = var.flow_logs_traffic_type
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs"
    }
  )

  depends_on = [aws_iam_role_policy.flow_logs]
}

################################################################################
# VPC Endpoints - S3 (Gateway)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = local.create_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-s3-endpoint"
    }
  )
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = local.create_s3_endpoint ? local.private_subnet_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = local.create_s3_endpoint && local.public_subnet_count > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public[0].id
}

################################################################################
# VPC Endpoints - DynamoDB (Gateway)
################################################################################

resource "aws_vpc_endpoint" "dynamodb" {
  count = local.create_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-dynamodb-endpoint"
    }
  )
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  count = local.create_dynamodb_endpoint ? local.private_subnet_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  count = local.create_dynamodb_endpoint && local.public_subnet_count > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public[0].id
}

################################################################################
# Network ACLs - Public
################################################################################

resource "aws_network_acl" "public" {
  count = var.enable_network_acls && local.public_subnet_count > 0 ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-nacl"
      Type = "public"
    }
  )
}

resource "aws_network_acl_rule" "public_ingress" {
  count = var.enable_network_acls && local.public_subnet_count > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "public_egress" {
  count = var.enable_network_acls && local.public_subnet_count > 0 ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

################################################################################
# Network ACLs - Private
################################################################################

resource "aws_network_acl" "private" {
  count = var.enable_network_acls && local.private_subnet_count > 0 ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-nacl"
      Type = "private"
    }
  )
}

resource "aws_network_acl_rule" "private_ingress" {
  count = var.enable_network_acls && local.private_subnet_count > 0 ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_egress" {
  count = var.enable_network_acls && local.private_subnet_count > 0 ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

################################################################################
# Replica VPC (Multi-Region)
################################################################################

resource "aws_vpc" "replica" {
  count    = local.has_replication ? 1 : 0
  provider = aws.destination

  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.vpc_name}-replica"
      ReplicaOf = aws_vpc.this.id
    }
  )
}

# Replica Internet Gateway
resource "aws_internet_gateway" "replica" {
  count    = local.has_replication && local.public_subnet_count > 0 ? 1 : 0
  provider = aws.destination

  vpc_id = aws_vpc.replica[0].id

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.vpc_name}-replica-igw"
      ReplicaOf = aws_internet_gateway.this[0].id
    }
  )
}

# Replica Public Subnets
resource "aws_subnet" "replica_public" {
  count    = local.has_replication ? local.public_subnet_count : 0
  provider = aws.destination

  vpc_id                  = aws_vpc.replica[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.destination_azs_to_use[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.vpc_name}-replica-public-${local.destination_azs_to_use[count.index]}"
      Type      = "public"
      ReplicaOf = aws_subnet.public[count.index].id
    }
  )
}

# Replica Private Subnets
resource "aws_subnet" "replica_private" {
  count    = local.has_replication ? local.private_subnet_count : 0
  provider = aws.destination

  vpc_id            = aws_vpc.replica[0].id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.destination_azs_to_use[count.index]

  tags = merge(
    local.common_tags,
    {
      Name      = "${local.vpc_name}-replica-private-${local.destination_azs_to_use[count.index]}"
      Type      = "private"
      ReplicaOf = aws_subnet.private[count.index].id
    }
  )
}

# Replica NAT Gateway EIPs
resource "aws_eip" "replica_nat" {
  count    = local.has_replication ? local.nat_gateway_count : 0
  provider = aws.destination

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-replica-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.replica]
}

# Replica NAT Gateways
resource "aws_nat_gateway" "replica" {
  count    = local.has_replication ? local.nat_gateway_count : 0
  provider = aws.destination

  allocation_id = aws_eip.replica_nat[count.index].id
  subnet_id     = aws_subnet.replica_public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-replica-nat-${local.destination_azs_to_use[var.single_nat_gateway ? 0 : count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.replica]
}

# Replica Public Route Table
resource "aws_route_table" "replica_public" {
  count    = local.has_replication && local.public_subnet_count > 0 ? 1 : 0
  provider = aws.destination

  vpc_id = aws_vpc.replica[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-replica-public-rt"
      Type = "public"
    }
  )
}

resource "aws_route" "replica_public_internet_gateway" {
  count    = local.has_replication && local.public_subnet_count > 0 ? 1 : 0
  provider = aws.destination

  route_table_id         = aws_route_table.replica_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.replica[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "replica_public" {
  count    = local.has_replication ? local.public_subnet_count : 0
  provider = aws.destination

  subnet_id      = aws_subnet.replica_public[count.index].id
  route_table_id = aws_route_table.replica_public[0].id
}

# Replica Private Route Tables
resource "aws_route_table" "replica_private" {
  count    = local.has_replication ? local.private_subnet_count : 0
  provider = aws.destination

  vpc_id = aws_vpc.replica[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-replica-private-rt-${local.destination_azs_to_use[count.index]}"
      Type = "private"
    }
  )
}

resource "aws_route" "replica_private_nat_gateway" {
  count    = local.has_replication && var.enable_nat_gateway ? local.private_subnet_count : 0
  provider = aws.destination

  route_table_id         = aws_route_table.replica_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.replica[0].id : aws_nat_gateway.replica[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "replica_private" {
  count    = local.has_replication ? local.private_subnet_count : 0
  provider = aws.destination

  subnet_id      = aws_subnet.replica_private[count.index].id
  route_table_id = aws_route_table.replica_private[count.index].id
}
