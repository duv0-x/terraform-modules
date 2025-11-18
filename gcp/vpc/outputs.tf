################################################################################
# VPC Network Outputs
################################################################################

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.this.self_link
}

output "project_id" {
  description = "The project ID where the VPC is created"
  value       = var.project_id
}

output "routing_mode" {
  description = "The network-wide routing mode"
  value       = google_compute_network.this.routing_mode
}

################################################################################
# Subnet Outputs
################################################################################

output "subnets" {
  description = "Map of subnet resources"
  value       = google_compute_subnetwork.subnets
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.id]
}

output "subnet_names" {
  description = "List of subnet names"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.name]
}

output "subnet_self_links" {
  description = "List of subnet self links"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.self_link]
}

output "subnet_regions" {
  description = "Map of subnet names to their regions"
  value = {
    for name, subnet in google_compute_subnetwork.subnets :
    name => subnet.region
  }
}

output "subnet_ip_cidr_ranges" {
  description = "Map of subnet names to their IP CIDR ranges"
  value = {
    for name, subnet in google_compute_subnetwork.subnets :
    name => subnet.ip_cidr_range
  }
}

output "subnet_secondary_ranges" {
  description = "Map of subnet names to their secondary IP ranges"
  value = {
    for name, subnet in google_compute_subnetwork.subnets :
    name => subnet.secondary_ip_range
  }
}

################################################################################
# Cloud Router Outputs
################################################################################

output "router_ids" {
  description = "Map of region to Cloud Router IDs"
  value = {
    for region, router in google_compute_router.router :
    region => router.id
  }
}

output "router_names" {
  description = "Map of region to Cloud Router names"
  value = {
    for region, router in google_compute_router.router :
    region => router.name
  }
}

################################################################################
# Cloud NAT Outputs
################################################################################

output "nat_ids" {
  description = "Map of region to Cloud NAT IDs"
  value = {
    for region, nat in google_compute_router_nat.nat :
    region => nat.id
  }
}

output "nat_names" {
  description = "Map of region to Cloud NAT names"
  value = {
    for region, nat in google_compute_router_nat.nat :
    region => nat.name
  }
}

################################################################################
# Firewall Outputs
################################################################################

output "firewall_rules" {
  description = "Map of firewall rule resources"
  value       = google_compute_firewall.rules
}

output "firewall_rule_ids" {
  description = "List of firewall rule IDs"
  value       = [for rule in google_compute_firewall.rules : rule.id]
}

output "firewall_rule_names" {
  description = "List of firewall rule names"
  value       = [for rule in google_compute_firewall.rules : rule.name]
}

################################################################################
# VPC Peering Outputs
################################################################################

output "peering_ids" {
  description = "List of VPC peering IDs"
  value       = google_compute_network_peering.peering[*].id
}

output "peering_names" {
  description = "List of VPC peering names"
  value       = google_compute_network_peering.peering[*].name
}

output "peering_states" {
  description = "List of VPC peering states"
  value       = google_compute_network_peering.peering[*].state
}

################################################################################
# Replica VPC Outputs
################################################################################

output "replica_network_id" {
  description = "The ID of the replica VPC network"
  value       = local.has_replication ? google_compute_network.replica[0].id : null
}

output "replica_network_name" {
  description = "The name of the replica VPC network"
  value       = local.has_replication ? google_compute_network.replica[0].name : null
}

output "replica_network_self_link" {
  description = "The URI of the replica VPC network"
  value       = local.has_replication ? google_compute_network.replica[0].self_link : null
}

output "replica_subnet_ids" {
  description = "List of replica subnet IDs"
  value       = local.has_replication ? [for subnet in google_compute_subnetwork.replica_subnets : subnet.id] : []
}

output "replica_subnet_names" {
  description = "List of replica subnet names"
  value       = local.has_replication ? [for subnet in google_compute_subnetwork.replica_subnets : subnet.name] : []
}

output "replica_nat_ids" {
  description = "Map of region to replica Cloud NAT IDs"
  value = local.has_replication ? {
    for region, nat in google_compute_router_nat.replica_nat :
    region => nat.id
  } : {}
}

################################################################################
# Useful Combined Outputs
################################################################################

output "network" {
  description = "Complete VPC network resource object"
  value       = google_compute_network.this
}

output "regions_with_subnets" {
  description = "List of regions that have subnets"
  value       = local.regions
}

output "regions_with_nat" {
  description = "List of regions that have Cloud NAT"
  value       = local.nat_regions
}
