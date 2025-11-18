# Local values for computed configurations
locals {
  # Default tags applied to all resources
  default_tags = {
    Name        = "${var.resource_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "module-template"
  }

  # Computed resource name with environment suffix
  resource_full_name = "${var.resource_name}-${var.environment}"

  # Conditional configurations
  has_replication = var.with_replication && var.replication_region != ""

  # Complex computed values
  advanced_settings = merge(
    {
      default_setting = "value"
    },
    var.advanced_config
  )
}
