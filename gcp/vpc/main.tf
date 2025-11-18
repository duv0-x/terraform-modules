################################################################################
# VPC Network
################################################################################

resource "google_compute_network" "this" {
  project                         = var.project_id
  name                            = local.network_full_name
  description                     = var.description != "" ? var.description : "VPC network for ${var.environment}"
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  mtu                             = var.mtu
  delete_default_routes_on_create = var.delete_default_routes_on_create

  # Labels are only supported in Terraform >= 0.13
  # and Google provider >= 4.0
  dynamic "timeouts" {
    for_each = [1]
    content {
      create = "10m"
      update = "10m"
      delete = "10m"
    }
  }
}

################################################################################
# Subnets
################################################################################

resource "google_compute_subnetwork" "subnets" {
  for_each = { for idx, subnet in var.subnets : subnet.subnet_name => subnet }

  project       = var.project_id
  name          = each.value.subnet_name
  description   = each.value.description
  ip_cidr_range = each.value.subnet_ip
  region        = each.value.subnet_region
  network       = google_compute_network.this.id

  private_ip_google_access = coalesce(
    each.value.enable_private_access,
    var.enable_private_google_access
  )

  # Flow logs configuration
  dynamic "log_config" {
    for_each = each.value.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = lookup(each.value.flow_logs_config, "aggregation_interval", "INTERVAL_5_SEC")
      flow_sampling        = lookup(each.value.flow_logs_config, "flow_sampling", 0.5)
      metadata             = lookup(each.value.flow_logs_config, "metadata", "INCLUDE_ALL_METADATA")
    }
  }

  # Secondary IP ranges (for GKE pods/services)
  dynamic "secondary_ip_range" {
    for_each = lookup(var.secondary_ranges, each.value.subnet_name, [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  depends_on = [google_compute_network.this]
}

################################################################################
# Cloud Router (required for Cloud NAT)
################################################################################

resource "google_compute_router" "router" {
  for_each = toset(local.nat_regions)

  project = var.project_id
  name    = "${local.network_full_name}-router-${each.value}"
  region  = each.value
  network = google_compute_network.this.id

  bgp {
    asn = 64514
  }
}

################################################################################
# Cloud NAT
################################################################################

resource "google_compute_router_nat" "nat" {
  for_each = local.nat_configs

  project                            = var.project_id
  name                               = "${local.network_full_name}-nat-${each.key}"
  region                             = each.key
  router                             = google_compute_router.router[each.key].name
  nat_ip_allocate_option             = each.value.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat
  min_ports_per_vm                   = each.value.min_ports_per_vm

  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping

  # Logging configuration
  dynamic "log_config" {
    for_each = each.value.log_config_enable ? [1] : []
    content {
      enable = true
      filter = each.value.log_config_filter
    }
  }

  depends_on = [google_compute_router.router]
}

################################################################################
# Firewall Rules
################################################################################

resource "google_compute_firewall" "rules" {
  for_each = { for idx, rule in local.all_firewall_rules : rule.name => rule }

  project     = var.project_id
  name        = "${local.network_full_name}-${each.value.name}"
  description = each.value.description
  network     = google_compute_network.this.id
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges = lookup(each.value, "source_ranges", null)
  source_tags   = lookup(each.value, "source_tags", null)
  target_tags   = lookup(each.value, "target_tags", null)

  # Allow rules
  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  # Deny rules
  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }

  depends_on = [google_compute_network.this]
}

################################################################################
# VPC Peering
################################################################################

resource "google_compute_network_peering" "peering" {
  count = length(var.vpc_peering)

  name         = "${local.network_full_name}-peering-${count.index}"
  network      = google_compute_network.this.id
  peer_network = var.vpc_peering[count.index].peer_network_name

  export_custom_routes = var.vpc_peering[count.index].export_custom_routes
  import_custom_routes = var.vpc_peering[count.index].import_custom_routes

  depends_on = [google_compute_network.this]
}

################################################################################
# Replica VPC Network (Multi-Project)
################################################################################

resource "google_compute_network" "replica" {
  count    = local.has_replication ? 1 : 0
  provider = google.replica

  project                         = var.replica_project_id
  name                            = "${local.network_full_name}-replica"
  description                     = "Replica of ${local.network_full_name} for disaster recovery"
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  mtu                             = var.mtu
  delete_default_routes_on_create = var.delete_default_routes_on_create

  dynamic "timeouts" {
    for_each = [1]
    content {
      create = "10m"
      update = "10m"
      delete = "10m"
    }
  }
}

# Replica Subnets
resource "google_compute_subnetwork" "replica_subnets" {
  for_each = local.has_replication ? { for idx, subnet in var.subnets : subnet.subnet_name => subnet } : {}
  provider = google.replica

  project       = var.replica_project_id
  name          = "${each.value.subnet_name}-replica"
  description   = "Replica of ${each.value.subnet_name}"
  ip_cidr_range = each.value.subnet_ip
  region        = each.value.subnet_region
  network       = google_compute_network.replica[0].id

  private_ip_google_access = coalesce(
    each.value.enable_private_access,
    var.enable_private_google_access
  )

  # Flow logs configuration
  dynamic "log_config" {
    for_each = each.value.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = lookup(each.value.flow_logs_config, "aggregation_interval", "INTERVAL_5_SEC")
      flow_sampling        = lookup(each.value.flow_logs_config, "flow_sampling", 0.5)
      metadata             = lookup(each.value.flow_logs_config, "metadata", "INCLUDE_ALL_METADATA")
    }
  }

  # Secondary IP ranges
  dynamic "secondary_ip_range" {
    for_each = lookup(var.secondary_ranges, each.value.subnet_name, [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  depends_on = [google_compute_network.replica]
}

# Replica Cloud Routers
resource "google_compute_router" "replica_router" {
  for_each = local.has_replication ? toset(local.nat_regions) : []
  provider = google.replica

  project = var.replica_project_id
  name    = "${local.network_full_name}-replica-router-${each.value}"
  region  = each.value
  network = google_compute_network.replica[0].id

  bgp {
    asn = 64514
  }
}

# Replica Cloud NAT
resource "google_compute_router_nat" "replica_nat" {
  for_each = local.has_replication ? local.nat_configs : {}
  provider = google.replica

  project                            = var.replica_project_id
  name                               = "${local.network_full_name}-replica-nat-${each.key}"
  region                             = each.key
  router                             = google_compute_router.replica_router[each.key].name
  nat_ip_allocate_option             = each.value.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat
  min_ports_per_vm                   = each.value.min_ports_per_vm

  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping

  dynamic "log_config" {
    for_each = each.value.log_config_enable ? [1] : []
    content {
      enable = true
      filter = each.value.log_config_filter
    }
  }

  depends_on = [google_compute_router.replica_router]
}

# Replica Firewall Rules
resource "google_compute_firewall" "replica_rules" {
  for_each = local.has_replication ? { for idx, rule in local.all_firewall_rules : rule.name => rule } : {}
  provider = google.replica

  project     = var.replica_project_id
  name        = "${local.network_full_name}-replica-${each.value.name}"
  description = each.value.description
  network     = google_compute_network.replica[0].id
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges = lookup(each.value, "source_ranges", null)
  source_tags   = lookup(each.value, "source_tags", null)
  target_tags   = lookup(each.value, "target_tags", null)

  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }

  depends_on = [google_compute_network.replica]
}
