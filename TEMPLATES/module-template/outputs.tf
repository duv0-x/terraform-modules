# Primary resource outputs
output "id" {
  description = "The ID of the created resource"
  value       = provider_resource_type.this.id
}

output "arn" {
  description = "The ARN of the created resource"
  value       = provider_resource_type.this.arn
}

output "name" {
  description = "The name of the created resource"
  value       = provider_resource_type.this.name
}

# Full resource object (useful for advanced use cases)
output "resource" {
  description = "The complete resource object"
  value       = provider_resource_type.this
}

# Replica outputs (conditional)
output "replica_id" {
  description = "The ID of the replica resource (if replication is enabled)"
  value       = var.with_replication ? provider_resource_type.replica[0].id : null
}

output "replica_arn" {
  description = "The ARN of the replica resource (if replication is enabled)"
  value       = var.with_replication ? provider_resource_type.replica[0].arn : null
}

# Sensitive outputs (if applicable)
output "connection_string" {
  description = "Connection string for the resource (sensitive)"
  value       = provider_resource_type.this.connection_string
  sensitive   = true
}
