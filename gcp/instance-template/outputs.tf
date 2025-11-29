output "id" {
  description = "ID of the instance template"
  value       = google_compute_instance_template.this.id
}

output "name" {
  description = "Name of the instance template"
  value       = google_compute_instance_template.this.name
}

output "self_link" {
  description = "Self link of the instance template"
  value       = google_compute_instance_template.this.self_link
}

output "self_link_unique" {
  description = "Unique self link of the instance template (includes timestamp)"
  value       = google_compute_instance_template.this.self_link_unique
}

output "metadata_fingerprint" {
  description = "Metadata fingerprint of the instance template"
  value       = google_compute_instance_template.this.metadata_fingerprint
}

output "tags_fingerprint" {
  description = "Tags fingerprint of the instance template"
  value       = google_compute_instance_template.this.tags_fingerprint
}

# Replica outputs
output "replica_id" {
  description = "ID of the replica instance template"
  value       = var.with_replication ? google_compute_instance_template.replica[0].id : null
}

output "replica_name" {
  description = "Name of the replica instance template"
  value       = var.with_replication ? google_compute_instance_template.replica[0].name : null
}

output "replica_self_link" {
  description = "Self link of the replica instance template"
  value       = var.with_replication ? google_compute_instance_template.replica[0].self_link : null
}

output "replica_self_link_unique" {
  description = "Unique self link of the replica instance template"
  value       = var.with_replication ? google_compute_instance_template.replica[0].self_link_unique : null
}
