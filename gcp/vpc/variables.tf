# Core VPC configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string

  validation {
    condition     = length(var.network_name) > 0 && length(var.network_name) <= 63
    error_message = "Network name must be between 1 and 63 characters."
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID is required."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# Network configuration
variable "auto_create_subnetworks" {
  description = "Auto-create subnetworks in each region (not recommended for production)"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be either REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes (1460 or 1500)"
  type        = number
  default     = 1460

  validation {
    condition     = contains([1460, 1500], var.mtu)
    error_message = "MTU must be either 1460 or 1500."
  }
}

variable "delete_default_routes_on_create" {
  description = "Delete default routes (0.0.0.0/0) on network creation"
  type        = bool
  default     = false
}

# Subnet configuration
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    subnet_name           = string
    subnet_ip             = string
    subnet_region         = string
    description           = optional(string, "")
    enable_private_access = optional(bool, true)
    enable_flow_logs      = optional(bool, false)
    flow_logs_config = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
    }), {})
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrhost(s.subnet_ip, 0))])
    error_message = "All subnet IPs must be valid CIDR blocks."
  }
}

variable "secondary_ranges" {
  description = "Secondary IP ranges for subnets (for GKE pods/services)"
  type = map(list(object({
    range_name    = string
    ip_cidr_range = string
  })))
  default = {}
}

# Cloud NAT configuration
variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for private subnet internet access"
  type        = bool
  default     = true
}

variable "cloud_nat_config" {
  description = "Cloud NAT configuration per region"
  type = map(object({
    enable_nat                            = optional(bool, true)
    nat_ip_allocate_option                = optional(string, "AUTO_ONLY")
    source_subnetwork_ip_ranges_to_nat    = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")
    min_ports_per_vm                      = optional(number, 64)
    enable_dynamic_port_allocation        = optional(bool, true)
    enable_endpoint_independent_mapping   = optional(bool, false)
    log_config_enable                     = optional(bool, false)
    log_config_filter                     = optional(string, "ERRORS_ONLY")
  }))
  default = {}
}

# Firewall rules
variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    name          = string
    description   = optional(string, "")
    direction     = optional(string, "INGRESS")
    priority      = optional(number, 1000)
    source_ranges = optional(list(string), [])
    source_tags   = optional(list(string), [])
    target_tags   = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  default = []
}

variable "enable_default_firewall_rules" {
  description = "Create default firewall rules (SSH, ICMP, internal)"
  type        = bool
  default     = true
}

# VPC Peering
variable "vpc_peering" {
  description = "VPC peering configurations"
  type = list(object({
    peer_network_name = string
    peer_project_id   = optional(string, "")
    export_custom_routes = optional(bool, false)
    import_custom_routes = optional(bool, false)
  }))
  default = []
}

# Multi-region replication
variable "with_replication" {
  description = "Create a replica VPC in another project/region for disaster recovery"
  type        = bool
  default     = false
}

variable "replica_project_id" {
  description = "GCP Project ID for replica VPC (required if with_replication is true)"
  type        = string
  default     = ""
}

# DNS configuration
variable "enable_private_google_access" {
  description = "Enable Private Google Access for all subnets"
  type        = bool
  default     = true
}

# Tagging and labels
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Description of the VPC network"
  type        = string
  default     = ""
}
