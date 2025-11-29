variable "template_name" {
  description = "Name of the instance template"
  type        = string

  validation {
    condition     = length(var.template_name) > 0 && length(var.template_name) <= 63
    error_message = "Template name must be between 1 and 63 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the instance template"
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Machine type to use for instances"
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Source image for boot disk"
  type        = string
  default     = null
}

variable "source_image_family" {
  description = "Source image family for boot disk (alternative to source_image)"
  type        = string
  default     = null
}

variable "source_image_project" {
  description = "Project where the source image resides"
  type        = string
  default     = null
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM features"
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Enable Secure Boot (requires Shielded VM)"
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Enable vTPM (requires Shielded VM)"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring (requires Shielded VM)"
  type        = bool
  default     = true
}

variable "enable_confidential_computing" {
  description = "Enable Confidential Computing (requires N2D instances)"
  type        = bool
  default     = false
}

variable "enable_display" {
  description = "Enable virtual display"
  type        = bool
  default     = false
}

variable "can_ip_forward" {
  description = "Enable IP forwarding"
  type        = bool
  default     = false
}

variable "network_tier" {
  description = "Network tier for external IPs (PREMIUM or STANDARD)"
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "Network tier must be either 'PREMIUM' or 'STANDARD'."
  }
}

variable "boot_disk" {
  description = "Boot disk configuration"
  type = object({
    auto_delete  = optional(bool, true)
    boot         = optional(bool, true)
    disk_size_gb = optional(number, 20)
    disk_type    = optional(string, "pd-standard")
    mode         = optional(string, "READ_WRITE")
    disk_labels  = optional(map(string), {})
  })
  default = {}
}

variable "additional_disks" {
  description = "Additional disk configurations"
  type = list(object({
    auto_delete  = optional(bool, true)
    boot         = optional(bool, false)
    device_name  = optional(string)
    disk_size_gb = optional(number)
    disk_type    = optional(string, "pd-standard")
    disk_name    = optional(string)
    mode         = optional(string, "READ_WRITE")
    source       = optional(string)
    disk_labels  = optional(map(string), {})
  }))
  default = []
}

variable "network_interfaces" {
  description = "Network interface configurations"
  type = list(object({
    network            = optional(string)
    subnetwork         = optional(string)
    subnetwork_project = optional(string)
    network_ip         = optional(string)
    nic_type           = optional(string)
    stack_type         = optional(string)
    queue_count        = optional(number)
    access_config = optional(list(object({
      nat_ip                 = optional(string)
      network_tier           = optional(string)
      public_ptr_domain_name = optional(string)
    })), [])
    ipv6_access_config = optional(list(object({
      network_tier           = optional(string)
      public_ptr_domain_name = optional(string)
    })), [])
    alias_ip_ranges = optional(list(object({
      ip_cidr_range         = string
      subnetwork_range_name = optional(string)
    })), [])
  }))
  default = []

  validation {
    condition     = length(var.network_interfaces) > 0 || var.network_interfaces == []
    error_message = "At least one network interface must be specified or use default."
  }
}

variable "service_account" {
  description = "Service account configuration"
  type = object({
    email  = string
    scopes = list(string)
  })
  default = null
}

variable "metadata" {
  description = "Instance metadata"
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Startup script to run on instance creation"
  type        = string
  default     = null
}

variable "enable_ssh_keys_metadata" {
  description = "Enable SSH keys in metadata"
  type        = bool
  default     = true
}

variable "ssh_keys" {
  description = "List of SSH public keys for instance access"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the instance template"
  type        = map(string)
  default     = {}
}

variable "scheduling" {
  description = "Scheduling configuration for instances"
  type = object({
    automatic_restart   = optional(bool, true)
    on_host_maintenance = optional(string, "MIGRATE")
    preemptible         = optional(bool, false)
    provisioning_model  = optional(string)
  })
  default = {}

  validation {
    condition = var.scheduling.on_host_maintenance == null || contains(
      ["MIGRATE", "TERMINATE"],
      var.scheduling.on_host_maintenance
    )
    error_message = "on_host_maintenance must be either 'MIGRATE' or 'TERMINATE'."
  }
}

variable "enable_spot_vm" {
  description = "Enable Spot VM (preemptible alternative)"
  type        = bool
  default     = false
}

variable "spot_instance_termination_action" {
  description = "Action to take when Spot VM is terminated (STOP or DELETE)"
  type        = string
  default     = "STOP"

  validation {
    condition     = contains(["STOP", "DELETE"], var.spot_instance_termination_action)
    error_message = "Spot instance termination action must be either 'STOP' or 'DELETE'."
  }
}

variable "guest_accelerators" {
  description = "List of guest accelerators (GPUs)"
  type = list(object({
    type  = string
    count = number
  }))
  default = []
}

variable "min_cpu_platform" {
  description = "Minimum CPU platform"
  type        = string
  default     = null
}

variable "advanced_machine_features" {
  description = "Advanced machine features"
  type = object({
    enable_nested_virtualization = optional(bool)
    threads_per_core             = optional(number)
    visible_core_count           = optional(number)
  })
  default = null
}

variable "reservation_affinity" {
  description = "Reservation affinity configuration"
  type = object({
    type = string
    specific_reservation = optional(object({
      key    = string
      values = list(string)
    }))
  })
  default = null

  validation {
    condition = var.reservation_affinity == null || contains(
      ["ANY_RESERVATION", "SPECIFIC_RESERVATION", "NO_RESERVATION"],
      var.reservation_affinity.type
    )
    error_message = "Reservation affinity type must be one of: ANY_RESERVATION, SPECIFIC_RESERVATION, NO_RESERVATION."
  }
}

variable "resource_policies" {
  description = "List of resource policy IDs"
  type        = list(string)
  default     = []
}

# Replication variables
variable "with_replication" {
  description = "Enable replication to another project"
  type        = bool
  default     = false
}

variable "replica_project_id" {
  description = "GCP project ID for replica"
  type        = string
  default     = null
}

variable "replica_region" {
  description = "GCP region for replica resources"
  type        = string
  default     = null
}

variable "replica_network_interfaces" {
  description = "Network interface configurations for replica"
  type = list(object({
    network            = optional(string)
    subnetwork         = optional(string)
    subnetwork_project = optional(string)
    network_ip         = optional(string)
    nic_type           = optional(string)
    stack_type         = optional(string)
    queue_count        = optional(number)
    access_config = optional(list(object({
      nat_ip                 = optional(string)
      network_tier           = optional(string)
      public_ptr_domain_name = optional(string)
    })), [])
    ipv6_access_config = optional(list(object({
      network_tier           = optional(string)
      public_ptr_domain_name = optional(string)
    })), [])
    alias_ip_ranges = optional(list(object({
      ip_cidr_range         = string
      subnetwork_range_name = optional(string)
    })), [])
  }))
  default = []
}

variable "replica_source_image" {
  description = "Source image for replica boot disk"
  type        = string
  default     = null
}

variable "replica_source_image_family" {
  description = "Source image family for replica boot disk"
  type        = string
  default     = null
}

variable "replica_metadata_startup_script" {
  description = "Startup script for replica instances"
  type        = string
  default     = null
}