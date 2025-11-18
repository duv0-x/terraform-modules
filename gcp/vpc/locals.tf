# Local values for computed configurations
locals {
  # Network naming
  network_full_name = "${var.network_name}-${var.environment}"

  # Default labels applied to all resources
  default_labels = {
    name        = local.network_full_name
    environment = var.environment
    managed_by  = "terraform"
    module      = "gcp-vpc"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(local.default_labels, var.labels)

  # Extract unique regions from subnets
  regions = distinct([for s in var.subnets : s.subnet_region])

  # Create a map of regions to their subnets
  subnets_by_region = {
    for region in local.regions :
    region => [for s in var.subnets : s if s.subnet_region == region]
  }

  # Cloud NAT configuration per region
  nat_regions = var.enable_cloud_nat ? (
    length(var.cloud_nat_config) > 0 ? keys(var.cloud_nat_config) : local.regions
  ) : []

  # Determine which regions need Cloud NAT based on configuration
  nat_configs = {
    for region in local.nat_regions :
    region => lookup(var.cloud_nat_config, region, {
      enable_nat                            = true
      nat_ip_allocate_option                = "AUTO_ONLY"
      source_subnetwork_ip_ranges_to_nat    = "ALL_SUBNETWORKS_ALL_IP_RANGES"
      min_ports_per_vm                      = 64
      enable_dynamic_port_allocation        = true
      enable_endpoint_independent_mapping   = false
      log_config_enable                     = false
      log_config_filter                     = "ERRORS_ONLY"
    })
  }

  # Default firewall rules
  default_firewall_rules = var.enable_default_firewall_rules ? [
    {
      name          = "allow-ssh-ingress"
      description   = "Allow SSH from anywhere"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["ssh"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
      deny = []
    },
    {
      name          = "allow-icmp-ingress"
      description   = "Allow ICMP from anywhere"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "icmp"
        ports    = []
      }]
      deny = []
    },
    {
      name          = "allow-internal"
      description   = "Allow internal traffic between all subnets"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = [for s in var.subnets : s.subnet_ip]
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
        }, {
        protocol = "udp"
        ports    = ["0-65535"]
        }, {
        protocol = "icmp"
        ports    = []
      }]
      deny = []
    }
  ] : []

  # Combine default and custom firewall rules
  all_firewall_rules = concat(local.default_firewall_rules, var.firewall_rules)

  # Replication configuration
  has_replication = var.with_replication && var.replica_project_id != ""
}
