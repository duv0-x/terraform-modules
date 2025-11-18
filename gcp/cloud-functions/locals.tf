# Local values for computed configurations
locals {
  # Function naming
  function_full_name = "${var.function_name}-${var.environment}"

  # Default labels
  default_labels = {
    name        = local.function_full_name
    environment = var.environment
    managed_by  = "terraform"
    module      = "gcp-cloud-function"
  }

  # Merge labels
  common_labels = merge(local.default_labels, var.labels)

  # Determine trigger type
  is_http_trigger   = var.trigger_http
  is_event_trigger  = var.event_trigger != null
  has_vpc_connector = var.vpc_connector != ""

  # Service account
  service_account = var.service_account_email != "" ? var.service_account_email : null

  # Invoker members for IAM
  invoker_members = concat(
    var.enable_public_access ? ["allUsers"] : [],
    var.invoker_members
  )

  # Replication configuration
  has_replication = var.with_replication && var.replica_region != ""
}
