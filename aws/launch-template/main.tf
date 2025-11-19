resource "aws_launch_template" "this" {
  name        = local.resource_full_name
  description = var.description

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  ebs_optimized = var.enable_ebs_optimization

  # Instance requirements (attribute-based instance type selection)
  dynamic "instance_requirements" {
    for_each = var.instance_requirements != null ? [var.instance_requirements] : []

    content {
      dynamic "vcpu_count" {
        for_each = instance_requirements.value.vcpu_count != null ? [instance_requirements.value.vcpu_count] : []
        content {
          min = vcpu_count.value.min
          max = vcpu_count.value.max
        }
      }

      dynamic "memory_mib" {
        for_each = instance_requirements.value.memory_mib != null ? [instance_requirements.value.memory_mib] : []
        content {
          min = memory_mib.value.min
          max = memory_mib.value.max
        }
      }

      cpu_manufacturers                                = instance_requirements.value.cpu_manufacturers
      instance_generations                             = instance_requirements.value.instance_generations
      burstable_performance                            = instance_requirements.value.burstable_performance
      spot_max_price_percentage_over_lowest_price      = instance_requirements.value.spot_max_price_percentage_over_lowest_price
      on_demand_max_price_percentage_over_lowest_price = instance_requirements.value.on_demand_max_price_percentage_over_lowest_price
      excluded_instance_types                          = instance_requirements.value.excluded_instance_types
      require_hibernate_support                        = instance_requirements.value.require_hibernate_support

      dynamic "network_interface_count" {
        for_each = instance_requirements.value.network_interface_count != null ? [instance_requirements.value.network_interface_count] : []
        content {
          min = network_interface_count.value.min
          max = network_interface_count.value.max
        }
      }

      dynamic "accelerator_count" {
        for_each = instance_requirements.value.accelerator_count != null ? [instance_requirements.value.accelerator_count] : []
        content {
          min = accelerator_count.value.min
          max = accelerator_count.value.max
        }
      }
    }
  }

  # IAM Instance Profile
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [var.iam_instance_profile] : []

    content {
      arn  = iam_instance_profile.value.arn
      name = iam_instance_profile.value.name
    }
  }

  # Network Interfaces
  dynamic "network_interfaces" {
    for_each = var.network_interfaces

    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      description                 = network_interfaces.value.description
      device_index                = network_interfaces.value.device_index
      interface_type              = network_interfaces.value.interface_type
      ipv4_address_count          = network_interfaces.value.ipv4_address_count
      ipv4_addresses              = network_interfaces.value.ipv4_addresses
      ipv6_address_count          = network_interfaces.value.ipv6_address_count
      ipv6_addresses              = network_interfaces.value.ipv6_addresses
      network_interface_id        = network_interfaces.value.network_interface_id
      private_ip_address          = network_interfaces.value.private_ip_address
      security_groups             = network_interfaces.value.security_groups
      subnet_id                   = network_interfaces.value.subnet_id
    }
  }

  # Security Groups (only if network_interfaces is not specified)
  vpc_security_group_ids = length(var.network_interfaces) == 0 ? var.vpc_security_group_ids : null

  # Block Device Mappings
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = block_device_mappings.value.no_device
      virtual_name = block_device_mappings.value.virtual_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []

        content {
          delete_on_termination = ebs.value.delete_on_termination
          encrypted             = ebs.value.encrypted
          iops                  = ebs.value.iops
          kms_key_id            = ebs.value.kms_key_id
          snapshot_id           = ebs.value.snapshot_id
          throughput            = ebs.value.throughput
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
        }
      }
    }
  }

  # Metadata Options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = var.metadata_hop_limit
    http_protocol_ipv6          = "disabled"
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = var.enable_monitoring
  }

  # Credit Specification (for T2/T3 instances)
  dynamic "credit_specification" {
    for_each = var.enable_credit_specification ? [1] : []

    content {
      cpu_credits = var.cpu_credits
    }
  }

  # Enclave Options
  dynamic "enclave_options" {
    for_each = var.enable_enclave ? [1] : []

    content {
      enabled = true
    }
  }

  # Placement
  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []

    content {
      availability_zone       = placement.value.availability_zone
      affinity                = placement.value.affinity
      group_name              = placement.value.group_name
      host_id                 = placement.value.host_id
      host_resource_group_arn = placement.value.host_resource_group_arn
      partition_number        = placement.value.partition_number
      spread_domain           = placement.value.spread_domain
      tenancy                 = placement.value.tenancy
    }
  }

  # Capacity Reservation
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation != null ? [var.capacity_reservation] : []

    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []

        content {
          capacity_reservation_id                 = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }

  # License Specifications
  dynamic "license_specification" {
    for_each = var.license_specifications

    content {
      license_configuration_arn = license_specification.value
    }
  }

  # User Data
  user_data = local.user_data

  # Disable API Termination
  disable_api_termination = var.enable_termination_protection

  # Tag Specifications
  dynamic "tag_specifications" {
    for_each = var.tag_specifications

    content {
      resource_type = tag_specifications.value
      tags          = local.common_tags
    }
  }

  tags = local.common_tags
}

# Replica Launch Template (Multi-Region)
resource "aws_launch_template" "replica" {
  count = var.with_replication ? 1 : 0

  provider = aws.destination

  name        = local.resource_full_name
  description = var.description

  image_id      = local.replica_image_id
  instance_type = var.instance_type
  key_name      = local.replica_key_name

  ebs_optimized = var.enable_ebs_optimization

  # Instance requirements
  dynamic "instance_requirements" {
    for_each = var.instance_requirements != null ? [var.instance_requirements] : []

    content {
      dynamic "vcpu_count" {
        for_each = instance_requirements.value.vcpu_count != null ? [instance_requirements.value.vcpu_count] : []
        content {
          min = vcpu_count.value.min
          max = vcpu_count.value.max
        }
      }

      dynamic "memory_mib" {
        for_each = instance_requirements.value.memory_mib != null ? [instance_requirements.value.memory_mib] : []
        content {
          min = memory_mib.value.min
          max = memory_mib.value.max
        }
      }

      cpu_manufacturers                                = instance_requirements.value.cpu_manufacturers
      instance_generations                             = instance_requirements.value.instance_generations
      burstable_performance                            = instance_requirements.value.burstable_performance
      spot_max_price_percentage_over_lowest_price      = instance_requirements.value.spot_max_price_percentage_over_lowest_price
      on_demand_max_price_percentage_over_lowest_price = instance_requirements.value.on_demand_max_price_percentage_over_lowest_price
      excluded_instance_types                          = instance_requirements.value.excluded_instance_types
      require_hibernate_support                        = instance_requirements.value.require_hibernate_support

      dynamic "network_interface_count" {
        for_each = instance_requirements.value.network_interface_count != null ? [instance_requirements.value.network_interface_count] : []
        content {
          min = network_interface_count.value.min
          max = network_interface_count.value.max
        }
      }

      dynamic "accelerator_count" {
        for_each = instance_requirements.value.accelerator_count != null ? [instance_requirements.value.accelerator_count] : []
        content {
          min = accelerator_count.value.min
          max = accelerator_count.value.max
        }
      }
    }
  }

  # IAM Instance Profile
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [var.iam_instance_profile] : []

    content {
      arn  = iam_instance_profile.value.arn
      name = iam_instance_profile.value.name
    }
  }

  # Network Interfaces (replica)
  dynamic "network_interfaces" {
    for_each = length(var.replica_network_interfaces) > 0 ? var.replica_network_interfaces : var.network_interfaces

    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      description                 = network_interfaces.value.description
      device_index                = network_interfaces.value.device_index
      interface_type              = network_interfaces.value.interface_type
      ipv4_address_count          = network_interfaces.value.ipv4_address_count
      ipv4_addresses              = network_interfaces.value.ipv4_addresses
      ipv6_address_count          = network_interfaces.value.ipv6_address_count
      ipv6_addresses              = network_interfaces.value.ipv6_addresses
      network_interface_id        = network_interfaces.value.network_interface_id
      private_ip_address          = network_interfaces.value.private_ip_address
      security_groups             = network_interfaces.value.security_groups
      subnet_id                   = network_interfaces.value.subnet_id
    }
  }

  # Security Groups (replica)
  vpc_security_group_ids = length(var.replica_network_interfaces) == 0 && length(var.network_interfaces) == 0 ? (
    length(var.replica_vpc_security_group_ids) > 0 ? var.replica_vpc_security_group_ids : var.vpc_security_group_ids
  ) : null

  # Block Device Mappings (same as primary)
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = block_device_mappings.value.no_device
      virtual_name = block_device_mappings.value.virtual_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs != null ? [block_device_mappings.value.ebs] : []

        content {
          delete_on_termination = ebs.value.delete_on_termination
          encrypted             = ebs.value.encrypted
          iops                  = ebs.value.iops
          kms_key_id            = ebs.value.kms_key_id
          snapshot_id           = ebs.value.snapshot_id
          throughput            = ebs.value.throughput
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
        }
      }
    }
  }

  # Metadata Options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enable_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = var.metadata_hop_limit
    http_protocol_ipv6          = "disabled"
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = var.enable_monitoring
  }

  # Credit Specification
  dynamic "credit_specification" {
    for_each = var.enable_credit_specification ? [1] : []

    content {
      cpu_credits = var.cpu_credits
    }
  }

  # Enclave Options
  dynamic "enclave_options" {
    for_each = var.enable_enclave ? [1] : []

    content {
      enabled = true
    }
  }

  # Placement
  dynamic "placement" {
    for_each = var.placement != null ? [var.placement] : []

    content {
      availability_zone       = placement.value.availability_zone
      affinity                = placement.value.affinity
      group_name              = placement.value.group_name
      host_id                 = placement.value.host_id
      host_resource_group_arn = placement.value.host_resource_group_arn
      partition_number        = placement.value.partition_number
      spread_domain           = placement.value.spread_domain
      tenancy                 = placement.value.tenancy
    }
  }

  # Capacity Reservation
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation != null ? [var.capacity_reservation] : []

    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []

        content {
          capacity_reservation_id                 = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }

  # License Specifications
  dynamic "license_specification" {
    for_each = var.license_specifications

    content {
      license_configuration_arn = license_specification.value
    }
  }

  # User Data (replica)
  user_data = local.replica_user_data

  # Disable API Termination
  disable_api_termination = var.enable_termination_protection

  # Tag Specifications
  dynamic "tag_specifications" {
    for_each = var.tag_specifications

    content {
      resource_type = tag_specifications.value
      tags          = local.common_tags
    }
  }

  tags = local.common_tags
}