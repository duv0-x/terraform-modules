# GCP VPC Network Terraform Module

## Description

This module creates a complete Google Cloud VPC network with custom subnets, Cloud NAT, firewall rules, and optional features like VPC peering and multi-project replication.

## Features

- **Custom VPC Network** - Full control over network configuration
- **Regional Subnets** - Subnets in multiple regions with custom CIDR blocks
- **Cloud NAT** - Managed NAT service for private subnet internet access
- **Cloud Router** - Automatic creation for Cloud NAT
- **Firewall Rules** - Customizable ingress/egress rules
- **Default Firewall Rules** - SSH, ICMP, and internal traffic
- **VPC Flow Logs** - Per-subnet flow logging configuration
- **Secondary IP Ranges** - Support for GKE pods/services
- **VPC Peering** - Connect to other VPC networks
- **Multi-Project Replication** - Replica VPC for disaster recovery
- **Private Google Access** - Access Google APIs without public IPs
- **Flexible Routing** - REGIONAL or GLOBAL routing mode

## Usage

### Basic VPC with Subnets

```hcl
module "vpc" {
  source = "../../gcp/vpc"

  project_id   = "my-gcp-project"
  network_name = "production-network"
  environment  = "production"

  subnets = [
    {
      subnet_name           = "subnet-us-central1"
      subnet_ip             = "10.0.1.0/24"
      subnet_region         = "us-central1"
      enable_private_access = true
    },
    {
      subnet_name           = "subnet-us-east1"
      subnet_ip             = "10.0.2.0/24"
      subnet_region         = "us-east1"
      enable_private_access = true
    }
  ]

  enable_cloud_nat = true

  labels = {
    project = "myapp"
    team    = "platform"
  }
}
```

### VPC with Cloud NAT and Custom Firewall Rules

```hcl
module "vpc_with_nat" {
  source = "../../gcp/vpc"

  project_id   = "my-gcp-project"
  network_name = "app-network"
  environment  = "production"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "app-subnet-us-central1"
      subnet_ip             = "10.1.0.0/24"
      subnet_region         = "us-central1"
      enable_private_access = true
      enable_flow_logs      = true
      flow_logs_config = {
        aggregation_interval = "INTERVAL_5_SEC"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  ]

  enable_cloud_nat = true
  cloud_nat_config = {
    us-central1 = {
      enable_nat                         = true
      min_ports_per_vm                   = 128
      enable_dynamic_port_allocation     = true
      log_config_enable                  = true
      log_config_filter                  = "ERRORS_ONLY"
    }
  }

  firewall_rules = [
    {
      name          = "allow-http-https"
      description   = "Allow HTTP and HTTPS from anywhere"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    },
    {
      name          = "allow-app-internal"
      description   = "Allow internal app traffic"
      direction     = "INGRESS"
      priority      = 1000
      source_tags   = ["app"]
      target_tags   = ["database"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["5432", "3306"]
        }
      ]
    }
  ]

  labels = {
    environment = "production"
  }
}
```

### VPC with GKE Secondary Ranges

```hcl
module "gke_vpc" {
  source = "../../gcp/vpc"

  project_id   = "my-gcp-project"
  network_name = "gke-network"
  environment  = "production"

  subnets = [
    {
      subnet_name           = "gke-subnet"
      subnet_ip             = "10.0.0.0/22"
      subnet_region         = "us-central1"
      enable_private_access = true
    }
  ]

  # Secondary ranges for GKE pods and services
  secondary_ranges = {
    gke-subnet = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.4.0.0/14"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.8.0.0/20"
      }
    ]
  }

  enable_cloud_nat = true

  labels = {
    workload = "gke"
  }
}
```

### Multi-Project VPC Replication

```hcl
# Primary project provider
provider "google" {
  alias   = "primary"
  project = "primary-project-id"
  region  = "us-central1"
}

# DR project provider
provider "google" {
  alias   = "dr"
  project = "dr-project-id"
  region  = "us-west1"
}

module "vpc_with_dr" {
  source = "../../gcp/vpc"

  project_id   = "primary-project-id"
  network_name = "multi-project-vpc"
  environment  = "production"

  subnets = [
    {
      subnet_name           = "primary-subnet"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = "us-central1"
      enable_private_access = true
    }
  ]

  enable_cloud_nat = true

  # Enable replication
  with_replication   = true
  replica_project_id = "dr-project-id"

  providers = {
    google         = google.primary
    google.replica = google.dr
  }

  labels = {
    dr_enabled = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0 |
| google | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 5.0 |
| google.replica | >= 5.0 |

## Resources

| Resource Type | Description |
|---------------|-------------|
| google_compute_network | VPC network (primary and replica) |
| google_compute_subnetwork | Subnets in specified regions |
| google_compute_router | Cloud Router for NAT |
| google_compute_router_nat | Cloud NAT for private subnet internet access |
| google_compute_firewall | Firewall rules |
| google_compute_network_peering | VPC peering connections |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network_name | Name of the VPC network | `string` | n/a | yes |
| project_id | GCP Project ID | `string` | n/a | yes |
| environment | Environment name | `string` | `"dev"` | no |
| auto_create_subnetworks | Auto-create subnetworks | `bool` | `false` | no |
| routing_mode | Network routing mode (REGIONAL/GLOBAL) | `string` | `"REGIONAL"` | no |
| mtu | Maximum Transmission Unit (1460/1500) | `number` | `1460` | no |
| subnets | List of subnets to create | `list(object)` | `[]` | no |
| secondary_ranges | Secondary IP ranges for GKE | `map(list(object))` | `{}` | no |
| enable_cloud_nat | Enable Cloud NAT | `bool` | `true` | no |
| cloud_nat_config | Cloud NAT configuration per region | `map(object)` | `{}` | no |
| firewall_rules | List of firewall rules | `list(object)` | `[]` | no |
| enable_default_firewall_rules | Create default firewall rules | `bool` | `true` | no |
| vpc_peering | VPC peering configurations | `list(object)` | `[]` | no |
| with_replication | Create replica VPC | `bool` | `false` | no |
| replica_project_id | Project ID for replica VPC | `string` | `""` | no |
| labels | Labels for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC network ID |
| network_name | VPC network name |
| network_self_link | VPC network self link |
| subnet_ids | List of subnet IDs |
| subnet_names | List of subnet names |
| subnet_regions | Map of subnet names to regions |
| router_ids | Map of Cloud Router IDs |
| nat_ids | Map of Cloud NAT IDs |
| firewall_rule_ids | List of firewall rule IDs |
| replica_network_id | Replica VPC network ID |
| replica_subnet_ids | List of replica subnet IDs |

## Examples

See the [examples](./examples) directory:

- [basic](./examples/basic) - Simple VPC with subnets
- [with-nat](./examples/with-nat) - VPC with Cloud NAT and firewall rules
- [multi-region](./examples/multi-region) - Multi-region VPC with subnets

## Architecture

### GCP VPC with Cloud NAT

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC Network (Global)                         │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐│
│  │              Region: us-central1                           ││
│  │                                                            ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │   Subnet (10.0.1.0/24)                               │ ││
│  │  │   - Private Google Access: Enabled                   │ ││
│  │  │   - Flow Logs: Optional                              │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  │                         │                                  ││
│  │  ┌──────────────────────┴───────────────────────────────┐ ││
│  │  │   Cloud Router                                        │ ││
│  │  │   - ASN: 64514                                        │ ││
│  │  └──────────────────────┬───────────────────────────────┘ ││
│  │                         │                                  ││
│  │  ┌──────────────────────┴───────────────────────────────┐ ││
│  │  │   Cloud NAT                                           │ ││
│  │  │   - Auto-allocate IPs                                 │ ││
│  │  │   - Min 64 ports/VM                                   │ ││
│  │  │   - Dynamic port allocation                           │ ││
│  │  └───────────────────────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐│
│  │              Region: us-east1                              ││
│  │                                                            ││
│  │  ┌──────────────────────────────────────────────────────┐ ││
│  │  │   Subnet (10.0.2.0/24)                               │ ││
│  │  │   - Private Google Access: Enabled                   │ ││
│  │  └──────────────────────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Subnet Planning**: Use /24 subnets for small workloads, /22 or larger for GKE
2. **Private Google Access**: Enable for all private subnets to access Google APIs
3. **Cloud NAT**: Use for private instances that need internet access
4. **Firewall Rules**: Use target tags for granular control
5. **Secondary Ranges**: Pre-plan for GKE pod/service IP ranges
6. **Routing Mode**: Use GLOBAL for multi-region deployments
7. **Flow Logs**: Enable for production environments for troubleshooting
8. **Labels**: Use consistent labeling for cost tracking

## Cost Considerations

- **Cloud NAT**: ~$0.045/hour per gateway + $0.045/GB processed
- **VPC itself**: Free
- **VPC Flow Logs**: CloudWatch Logs storage costs
- **VPC Peering**: Data transfer charges between regions
- **Static IPs**: $0.01/hour if reserved but not used

## Differences from AWS VPC

| Feature | AWS | GCP |
|---------|-----|-----|
| Scope | Regional | Global |
| Subnets | Per AZ | Per Region |
| Internet Gateway | Explicit resource | Automatic |
| NAT | NAT Gateway | Cloud NAT |
| Security | Security Groups + NACLs | Firewall Rules |
| Routing | Route Tables | Routes in Network |
| DNS | Route53 Private Hosted Zones | Cloud DNS |

## License

Internal use only.
