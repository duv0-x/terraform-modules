locals {
  # Generate full resource name
  resource_full_name = "${var.template_name}-${var.environment}"

  # Default tags
  default_tags = {
    Name        = local.resource_full_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "aws-launch-template"
  }

  # Merge default and custom tags
  common_tags = merge(local.default_tags, var.tags)

  # Determine user data
  user_data = var.user_data_base64 != null ? var.user_data_base64 : (
    var.user_data != null ? base64encode(var.user_data) : null
  )

  # Determine replica user data
  replica_user_data = var.replica_user_data != null ? base64encode(var.replica_user_data) : local.user_data

  # Determine replica image ID
  replica_image_id = var.replica_image_id != null ? var.replica_image_id : var.image_id

  # Determine replica key name
  replica_key_name = var.replica_key_name != null ? var.replica_key_name : var.key_name
}