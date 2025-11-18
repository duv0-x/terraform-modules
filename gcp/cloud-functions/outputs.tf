################################################################################
# Cloud Function Outputs
################################################################################

output "function_id" {
  description = "The ID of the Cloud Function"
  value       = google_cloudfunctions2_function.this.id
}

output "function_name" {
  description = "The name of the Cloud Function"
  value       = google_cloudfunctions2_function.this.name
}

output "function_uri" {
  description = "The URI of the Cloud Function"
  value       = google_cloudfunctions2_function.this.service_config[0].uri
}

output "function_url" {
  description = "The HTTPS URL for invoking the function (if HTTP trigger is enabled)"
  value       = local.is_http_trigger ? google_cloudfunctions2_function.this.service_config[0].uri : null
}

output "function_region" {
  description = "The region where the function is deployed"
  value       = google_cloudfunctions2_function.this.location
}

output "function_state" {
  description = "The current state of the function"
  value       = google_cloudfunctions2_function.this.state
}

output "function_runtime" {
  description = "The runtime of the function"
  value       = google_cloudfunctions2_function.this.build_config[0].runtime
}

output "function_service_account" {
  description = "The service account email used by the function"
  value       = google_cloudfunctions2_function.this.service_config[0].service_account_email
}

output "function_environment_variables" {
  description = "Environment variables configured for the function"
  value       = google_cloudfunctions2_function.this.service_config[0].environment_variables
  sensitive   = true
}

output "function_labels" {
  description = "Labels applied to the function"
  value       = google_cloudfunctions2_function.this.labels
}

################################################################################
# Replica Function Outputs
################################################################################

output "replica_function_id" {
  description = "The ID of the replica Cloud Function"
  value       = local.has_replication ? google_cloudfunctions2_function.replica[0].id : null
}

output "replica_function_name" {
  description = "The name of the replica Cloud Function"
  value       = local.has_replication ? google_cloudfunctions2_function.replica[0].name : null
}

output "replica_function_uri" {
  description = "The URI of the replica Cloud Function"
  value       = local.has_replication ? google_cloudfunctions2_function.replica[0].service_config[0].uri : null
}

output "replica_function_url" {
  description = "The HTTPS URL for invoking the replica function"
  value       = local.has_replication && local.is_http_trigger ? google_cloudfunctions2_function.replica[0].service_config[0].uri : null
}

output "replica_function_region" {
  description = "The region where the replica function is deployed"
  value       = local.has_replication ? google_cloudfunctions2_function.replica[0].location : null
}

################################################################################
# Useful Combined Outputs
################################################################################

output "function" {
  description = "Complete Cloud Function resource object"
  value       = google_cloudfunctions2_function.this
  sensitive   = true
}

output "is_public" {
  description = "Whether the function allows public access"
  value       = var.enable_public_access
}

output "invoker_members" {
  description = "List of members who can invoke the function"
  value       = local.invoker_members
}
