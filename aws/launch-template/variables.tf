variable "template_name" {
  description = "Name of the launch template"
  type        = string

  validation {
    condition     = length(var.template_name) > 0 && length(var.template_name) <= 125
    error_message = "Template name must be between 1 and 125 characters."
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

variable "description" {
  description = "Description of the launch template"
  type        = string
  default     = null
}

variable "image_id" {
  description = "AMI ID to use for instances"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type to use. Conflicts with instance_requirements"
  type        = string
  default     = null
}

variable "instance_requirements" {
  description = "Instance requirements for attribute-based instance type selection. Conflicts with instance_type"
  type = object({
    vcpu_count = optional(object({
      min = optional(number, 1)
      max = optional(number)
    }), {})
    memory_mib = optional(object({
      min = optional(number, 512)
      max = optional(number)
    }), {})
    cpu_manufacturers                           = optional(list(string))
    instance_generations                        = optional(list(string))
    burstable_performance                       = optional(string)
    spot_max_price_percentage_over_lowest_price = optional(number)
    on_demand_max_price_percentage_over_lowest_price = optional(number)
    excluded_instance_types                     = optional(list(string))
    require_hibernate_support                   = optional(bool)
    network_interface_count = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    accelerator_count = optional(object({
      min = optional(number)
      max = optional(number)
    }))
  })
  default = null
}

variable "key_name" {
  description = "Key pair name to use for SSH access"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_imdsv2" {
  description = "Enable IMDSv2 (Instance Metadata Service Version 2) for enhanced security"
  type        = bool
  default     = true
}

variable "metadata_hop_limit" {
  description = "Hop limit for instance metadata service requests"
  type        = number
  default     = 1

  validation {
    condition     = var.metadata_hop_limit >= 1 && var.metadata_hop_limit <= 64
    error_message = "Metadata hop limit must be between 1 and 64."
  }
}

variable "enable_termination_protection" {
  description = "Enable instance termination protection"
  type        = bool
  default     = false
}

variable "enable_ebs_optimization" {
  description = "Enable EBS optimization"
  type        = bool
  default     = true
}

variable "iam_instance_profile" {
  description = "IAM instance profile to attach to launched instances"
  type = object({
    arn  = optional(string)
    name = optional(string)
  })
  default = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "network_interfaces" {
  description = "Network interface configurations"
  type = list(object({
    associate_public_ip_address = optional(bool)
    delete_on_termination       = optional(bool, true)
    description                 = optional(string)
    device_index                = optional(number, 0)
    interface_type              = optional(string)
    ipv4_address_count          = optional(number)
    ipv4_addresses              = optional(list(string))
    ipv6_address_count          = optional(number)
    ipv6_addresses              = optional(list(string))
    network_interface_id        = optional(string)
    private_ip_address          = optional(string)
    security_groups             = optional(list(string))
    subnet_id                   = optional(string)
  }))
  default = []
}

variable "block_device_mappings" {
  description = "Block device mappings for the launch template"
  type = list(object({
    device_name  = string
    no_device    = optional(bool)
    virtual_name = optional(string)
    ebs = optional(object({
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, true)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
    }))
  }))
  default = []
}

variable "user_data" {
  description = "User data script (will be base64 encoded automatically)"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64-encoded user data (use this if already encoded)"
  type        = string
  default     = null
}

variable "enable_credit_specification" {
  description = "Enable T2/T3 unlimited CPU credits"
  type        = bool
  default     = false
}

variable "cpu_credits" {
  description = "Credit option for CPU usage (standard or unlimited)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits must be either 'standard' or 'unlimited'."
  }
}

variable "enable_enclave" {
  description = "Enable AWS Nitro Enclaves"
  type        = bool
  default     = false
}

variable "placement" {
  description = "Placement configuration for instances"
  type = object({
    availability_zone      = optional(string)
    affinity               = optional(string)
    group_name             = optional(string)
    host_id                = optional(string)
    host_resource_group_arn = optional(string)
    partition_number       = optional(number)
    spread_domain          = optional(string)
    tenancy                = optional(string)
  })
  default = null
}

variable "capacity_reservation" {
  description = "Capacity reservation targeting configuration"
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id                 = optional(string)
      capacity_reservation_resource_group_arn = optional(string)
    }))
  })
  default = null
}

variable "license_specifications" {
  description = "List of license configuration ARNs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to the launch template"
  type        = map(string)
  default     = {}
}

variable "tag_specifications" {
  description = "Resource types to tag on creation"
  type        = list(string)
  default     = ["instance", "volume", "network-interface"]

  validation {
    condition = alltrue([
      for rt in var.tag_specifications : contains([
        "instance", "volume", "network-interface", "spot-instances-request"
      ], rt)
    ])
    error_message = "Tag specifications must be valid resource types."
  }
}

# Replication variables
variable "with_replication" {
  description = "Enable replication to another region"
  type        = bool
  default     = false
}

variable "replica_image_id" {
  description = "AMI ID for replica region (if different from primary)"
  type        = string
  default     = null
}

variable "replica_vpc_security_group_ids" {
  description = "Security group IDs for replica region"
  type        = list(string)
  default     = []
}

variable "replica_network_interfaces" {
  description = "Network interface configurations for replica region"
  type = list(object({
    associate_public_ip_address = optional(bool)
    delete_on_termination       = optional(bool, true)
    description                 = optional(string)
    device_index                = optional(number, 0)
    interface_type              = optional(string)
    ipv4_address_count          = optional(number)
    ipv4_addresses              = optional(list(string))
    ipv6_address_count          = optional(number)
    ipv6_addresses              = optional(list(string))
    network_interface_id        = optional(string)
    private_ip_address          = optional(string)
    security_groups             = optional(list(string))
    subnet_id                   = optional(string)
  }))
  default = []
}

variable "replica_user_data" {
  description = "User data script for replica region"
  type        = string
  default     = null
}

variable "replica_key_name" {
  description = "Key pair name for replica region"
  type        = string
  default     = null
}