resource "google_compute_instance_template" "this" {
  name_prefix = "${local.resource_full_name}-"
  description = var.description
  project     = var.project_id
  region      = var.region

  machine_type   = var.machine_type
  can_ip_forward = var.can_ip_forward
  tags           = var.tags
  labels         = local.common_labels

  # Boot Disk
  disk {
    auto_delete  = var.boot_disk.auto_delete
    boot         = var.boot_disk.boot
    disk_size_gb = var.boot_disk.disk_size_gb
    disk_type    = var.boot_disk.disk_type
    mode         = var.boot_disk.mode
    source_image = local.source_image
    labels       = merge(local.common_labels, var.boot_disk.disk_labels)

    # Enable encryption by default
    disk_encryption_key {
      kms_key_self_link = null # Set this if using CMEK
    }
  }

  # Additional Disks
  dynamic "disk" {
    for_each = var.additional_disks

    content {
      auto_delete  = disk.value.auto_delete
      boot         = disk.value.boot
      device_name  = disk.value.device_name
      disk_name    = disk.value.disk_name
      disk_size_gb = disk.value.disk_size_gb
      disk_type    = disk.value.disk_type
      mode         = disk.value.mode
      source       = disk.value.source
      labels       = merge(local.common_labels, disk.value.disk_labels)
    }
  }

  # Network Interfaces
  dynamic "network_interface" {
    for_each = local.network_interfaces

    content {
      network            = network_interface.value.network
      subnetwork         = network_interface.value.subnetwork
      subnetwork_project = network_interface.value.subnetwork_project
      network_ip         = network_interface.value.network_ip
      nic_type           = network_interface.value.nic_type
      stack_type         = network_interface.value.stack_type
      queue_count        = network_interface.value.queue_count

      # Access Config (External IP)
      dynamic "access_config" {
        for_each = network_interface.value.access_config

        content {
          nat_ip                 = access_config.value.nat_ip
          network_tier           = coalesce(access_config.value.network_tier, var.network_tier)
          public_ptr_domain_name = access_config.value.public_ptr_domain_name
        }
      }

      # IPv6 Access Config
      dynamic "ipv6_access_config" {
        for_each = network_interface.value.ipv6_access_config

        content {
          network_tier           = coalesce(ipv6_access_config.value.network_tier, var.network_tier)
          public_ptr_domain_name = ipv6_access_config.value.public_ptr_domain_name
        }
      }

      # Alias IP Ranges
      dynamic "alias_ip_range" {
        for_each = network_interface.value.alias_ip_ranges

        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
        }
      }
    }
  }

  # Service Account
  dynamic "service_account" {
    for_each = var.service_account != null ? [var.service_account] : []

    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }

  # Metadata
  metadata = local.metadata

  # Scheduling
  scheduling {
    automatic_restart   = local.scheduling.automatic_restart
    on_host_maintenance = local.scheduling.on_host_maintenance
    preemptible         = local.scheduling.preemptible
    provisioning_model  = local.scheduling.provisioning_model

    # Spot VM termination action
    dynamic "instance_termination_action" {
      for_each = var.enable_spot_vm ? [1] : []
      content {
        action = var.spot_instance_termination_action
      }
    }
  }

  # Shielded Instance Config
  dynamic "shielded_instance_config" {
    for_each = var.enable_shielded_vm ? [1] : []

    content {
      enable_secure_boot          = var.enable_secure_boot
      enable_vtpm                 = var.enable_vtpm
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }
  }

  # Confidential Instance Config
  dynamic "confidential_instance_config" {
    for_each = var.enable_confidential_computing ? [1] : []

    content {
      enable_confidential_compute = true
    }
  }

  # Guest Accelerators (GPUs)
  dynamic "guest_accelerator" {
    for_each = var.guest_accelerators

    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  # Advanced Machine Features
  dynamic "advanced_machine_features" {
    for_each = var.advanced_machine_features != null ? [var.advanced_machine_features] : []

    content {
      enable_nested_virtualization = advanced_machine_features.value.enable_nested_virtualization
      threads_per_core             = advanced_machine_features.value.threads_per_core
      visible_core_count           = advanced_machine_features.value.visible_core_count
    }
  }

  # Reservation Affinity
  dynamic "reservation_affinity" {
    for_each = var.reservation_affinity != null ? [var.reservation_affinity] : []

    content {
      type = reservation_affinity.value.type

      dynamic "specific_reservation" {
        for_each = reservation_affinity.value.specific_reservation != null ? [reservation_affinity.value.specific_reservation] : []

        content {
          key    = specific_reservation.value.key
          values = specific_reservation.value.values
        }
      }
    }
  }

  # Resource Policies
  resource_policies = var.resource_policies

  # Minimum CPU Platform
  min_cpu_platform = var.min_cpu_platform

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}

# Replica Instance Template (Multi-Project/Multi-Region)
resource "google_compute_instance_template" "replica" {
  count = var.with_replication ? 1 : 0

  provider = google.replica

  name_prefix = "${local.resource_full_name}-"
  description = var.description
  project     = coalesce(var.replica_project_id, var.project_id)
  region      = coalesce(var.replica_region, var.region)

  machine_type   = var.machine_type
  can_ip_forward = var.can_ip_forward
  tags           = var.tags
  labels         = local.common_labels

  # Boot Disk
  disk {
    auto_delete  = var.boot_disk.auto_delete
    boot         = var.boot_disk.boot
    disk_size_gb = var.boot_disk.disk_size_gb
    disk_type    = var.boot_disk.disk_type
    mode         = var.boot_disk.mode
    source_image = local.replica_source_image
    labels       = merge(local.common_labels, var.boot_disk.disk_labels)

    disk_encryption_key {
      kms_key_self_link = null
    }
  }

  # Additional Disks
  dynamic "disk" {
    for_each = var.additional_disks

    content {
      auto_delete  = disk.value.auto_delete
      boot         = disk.value.boot
      device_name  = disk.value.device_name
      disk_name    = disk.value.disk_name
      disk_size_gb = disk.value.disk_size_gb
      disk_type    = disk.value.disk_type
      mode         = disk.value.mode
      source       = disk.value.source
      labels       = merge(local.common_labels, disk.value.disk_labels)
    }
  }

  # Network Interfaces (use replica-specific if provided, otherwise use primary)
  dynamic "network_interface" {
    for_each = length(var.replica_network_interfaces) > 0 ? var.replica_network_interfaces : local.network_interfaces

    content {
      network            = network_interface.value.network
      subnetwork         = network_interface.value.subnetwork
      subnetwork_project = network_interface.value.subnetwork_project
      network_ip         = network_interface.value.network_ip
      nic_type           = network_interface.value.nic_type
      stack_type         = network_interface.value.stack_type
      queue_count        = network_interface.value.queue_count

      dynamic "access_config" {
        for_each = network_interface.value.access_config

        content {
          nat_ip                 = access_config.value.nat_ip
          network_tier           = coalesce(access_config.value.network_tier, var.network_tier)
          public_ptr_domain_name = access_config.value.public_ptr_domain_name
        }
      }

      dynamic "ipv6_access_config" {
        for_each = network_interface.value.ipv6_access_config

        content {
          network_tier           = coalesce(ipv6_access_config.value.network_tier, var.network_tier)
          public_ptr_domain_name = ipv6_access_config.value.public_ptr_domain_name
        }
      }

      dynamic "alias_ip_range" {
        for_each = network_interface.value.alias_ip_ranges

        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
        }
      }
    }
  }

  # Service Account
  dynamic "service_account" {
    for_each = var.service_account != null ? [var.service_account] : []

    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }

  # Metadata (replica)
  metadata = local.replica_metadata

  # Scheduling
  scheduling {
    automatic_restart   = local.scheduling.automatic_restart
    on_host_maintenance = local.scheduling.on_host_maintenance
    preemptible         = local.scheduling.preemptible
    provisioning_model  = local.scheduling.provisioning_model

    dynamic "instance_termination_action" {
      for_each = var.enable_spot_vm ? [1] : []
      content {
        action = var.spot_instance_termination_action
      }
    }
  }

  # Shielded Instance Config
  dynamic "shielded_instance_config" {
    for_each = var.enable_shielded_vm ? [1] : []

    content {
      enable_secure_boot          = var.enable_secure_boot
      enable_vtpm                 = var.enable_vtpm
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }
  }

  # Confidential Instance Config
  dynamic "confidential_instance_config" {
    for_each = var.enable_confidential_computing ? [1] : []

    content {
      enable_confidential_compute = true
    }
  }

  # Guest Accelerators
  dynamic "guest_accelerator" {
    for_each = var.guest_accelerators

    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  # Advanced Machine Features
  dynamic "advanced_machine_features" {
    for_each = var.advanced_machine_features != null ? [var.advanced_machine_features] : []

    content {
      enable_nested_virtualization = advanced_machine_features.value.enable_nested_virtualization
      threads_per_core             = advanced_machine_features.value.threads_per_core
      visible_core_count           = advanced_machine_features.value.visible_core_count
    }
  }

  # Reservation Affinity
  dynamic "reservation_affinity" {
    for_each = var.reservation_affinity != null ? [var.reservation_affinity] : []

    content {
      type = reservation_affinity.value.type

      dynamic "specific_reservation" {
        for_each = reservation_affinity.value.specific_reservation != null ? [reservation_affinity.value.specific_reservation] : []

        content {
          key    = specific_reservation.value.key
          values = specific_reservation.value.values
        }
      }
    }
  }

  # Resource Policies
  resource_policies = var.resource_policies

  # Minimum CPU Platform
  min_cpu_platform = var.min_cpu_platform

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}