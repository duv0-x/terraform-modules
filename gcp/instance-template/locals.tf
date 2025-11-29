locals {
  # Generate full resource name (GCP naming conventions - lowercase with hyphens)
  resource_full_name = lower("${var.template_name}-${var.environment}")

  # Default labels
  default_labels = {
    name        = local.resource_full_name
    environment = var.environment
    managed_by  = "terraform"
    module      = "gcp-instance-template"
  }

  # Merge default and custom labels
  common_labels = merge(local.default_labels, var.labels)

  # Determine source image
  source_image = var.source_image != null ? var.source_image : (
    var.source_image_family != null ? "projects/${coalesce(var.source_image_project, var.project_id)}/global/images/family/${var.source_image_family}" : null
  )

  # Determine replica source image
  replica_source_image = var.replica_source_image != null ? var.replica_source_image : (
    var.replica_source_image_family != null ? "projects/${coalesce(var.source_image_project, var.project_id)}/global/images/family/${var.replica_source_image_family}" : local.source_image
  )

  # Metadata with startup script and SSH keys
  metadata = merge(
    var.metadata,
    var.metadata_startup_script != null ? { "startup-script" = var.metadata_startup_script } : {},
    var.enable_ssh_keys_metadata && length(var.ssh_keys) > 0 ? { "ssh-keys" = join("\n", var.ssh_keys) } : {}
  )

  # Replica metadata
  replica_metadata = merge(
    var.metadata,
    var.replica_metadata_startup_script != null ? { "startup-script" = var.replica_metadata_startup_script } : (
      var.metadata_startup_script != null ? { "startup-script" = var.metadata_startup_script } : {}
    ),
    var.enable_ssh_keys_metadata && length(var.ssh_keys) > 0 ? { "ssh-keys" = join("\n", var.ssh_keys) } : {}
  )

  # Scheduling configuration
  scheduling = {
    automatic_restart   = var.enable_spot_vm ? false : var.scheduling.automatic_restart
    on_host_maintenance = var.enable_spot_vm ? "TERMINATE" : var.scheduling.on_host_maintenance
    preemptible         = var.scheduling.preemptible
    provisioning_model  = var.enable_spot_vm ? "SPOT" : var.scheduling.provisioning_model
  }

  # Default network interface if none specified
  default_network_interface = [
    {
      network            = "default"
      subnetwork         = null
      subnetwork_project = null
      network_ip         = null
      nic_type           = null
      stack_type         = null
      queue_count        = null
      access_config      = []
      ipv6_access_config = []
      alias_ip_ranges    = []
    }
  ]

  network_interfaces = length(var.network_interfaces) > 0 ? var.network_interfaces : local.default_network_interface
}
