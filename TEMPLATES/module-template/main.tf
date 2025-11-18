# Main resource definitions for the module
# Replace 'example' with your actual resource type

resource "provider_resource_type" "this" {
  name = var.resource_name

  # Enable conditional features using dynamic blocks
  dynamic "optional_feature" {
    for_each = var.enable_optional_feature ? [1] : []
    content {
      # Configuration for optional feature
    }
  }

  # Merge default tags with user-provided tags
  tags = merge(
    local.default_tags,
    var.tags
  )
}

# Replica resource for multi-region/multi-account deployments
resource "provider_resource_type" "replica" {
  count    = var.with_replication ? 1 : 0
  provider = provider.destination

  name = "${var.resource_name}-replica"

  # Replicate configuration from primary resource
  # Add replication-specific configuration here

  tags = merge(
    local.default_tags,
    var.tags,
    {
      ReplicaOf = provider_resource_type.this.id
    }
  )
}
