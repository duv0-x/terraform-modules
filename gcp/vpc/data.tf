# Get current project information
data "google_project" "current" {
  project_id = var.project_id
}

# Get available regions
data "google_compute_regions" "available" {
  project = var.project_id
}

# Get replica project information (for replication)
data "google_project" "replica" {
  count      = var.with_replication ? 1 : 0
  project_id = var.replica_project_id
  provider   = google.replica
}
