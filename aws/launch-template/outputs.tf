output "id" {
  description = "ID of the launch template"
  value       = aws_launch_template.this.id
}

output "arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.this.arn
}

output "name" {
  description = "Name of the launch template"
  value       = aws_launch_template.this.name
}

output "latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "default_version" {
  description = "Default version of the launch template"
  value       = aws_launch_template.this.default_version
}

output "tags_all" {
  description = "All tags applied to the launch template"
  value       = aws_launch_template.this.tags_all
}

# Replica outputs
output "replica_id" {
  description = "ID of the replica launch template"
  value       = var.with_replication ? aws_launch_template.replica[0].id : null
}

output "replica_arn" {
  description = "ARN of the replica launch template"
  value       = var.with_replication ? aws_launch_template.replica[0].arn : null
}

output "replica_name" {
  description = "Name of the replica launch template"
  value       = var.with_replication ? aws_launch_template.replica[0].name : null
}

output "replica_latest_version" {
  description = "Latest version of the replica launch template"
  value       = var.with_replication ? aws_launch_template.replica[0].latest_version : null
}

output "replica_default_version" {
  description = "Default version of the replica launch template"
  value       = var.with_replication ? aws_launch_template.replica[0].default_version : null
}