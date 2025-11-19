# GCP Instance Template Module

Terraform module to create and manage GCP Compute Engine Instance Templates with comprehensive configuration options and multi-project/multi-region replication support.

## Features

- **Modern Security Defaults**: Shielded VM enabled by default with Secure Boot, vTPM, and Integrity Monitoring
- **Confidential Computing**: Support for Confidential VMs using AMD SEV technology
- **Spot VM Support**: Configure Spot VMs with custom termination actions
- **Flexible Disk Configuration**: Support for multiple disk types including persistent disks, local SSDs
- **Advanced Networking**: Multiple network interfaces, alias IP ranges, IPv6 support
- **Multi-Project/Region Replication**: Built-in support for cross-project and cross-region templates
- **GPU Support**: Configure guest accelerators for ML/AI workloads
- **Terraform 1.8+ Features**: Uses optional attributes and advanced validations

## Requirements

- Terraform >= 1.8.0
- Google Cloud Provider >= 5.0

## Usage

### Basic Example

```hcl
module "instance_template" {
  source = "./gcp/instance-template"

  template_name = "web-server"
  environment   = "production"
  project_id    = "my-gcp-project"
  region        = "us-central1"

  machine_type         = "e2-medium"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  network_interfaces = [
    {
      subnetwork         = "projects/my-gcp-project/regions/us-central1/subnetworks/default"
      subnetwork_project = "my-gcp-project"
      access_config = [
        {
          network_tier = "PREMIUM"
        }
      ]
    }
  ]

  service_account = {
    email = "compute@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = ["web", "https-server"]

  labels = {
    application = "webapp"
    team        = "devops"
  }
}
```

### Advanced Example with Shielded VM and Custom Disks

```hcl
module "secure_instance_template" {
  source = "./gcp/instance-template"

  template_name = "secure-compute"
  environment   = "production"
  project_id    = "my-gcp-project"
  region        = "us-central1"

  machine_type         = "n2-standard-4"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # Shielded VM configuration
  enable_shielded_vm          = true
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true

  # Boot disk configuration
  boot_disk = {
    auto_delete  = true
    disk_size_gb = 100
    disk_type    = "pd-ssd"
    disk_labels = {
      disk_type = "boot"
    }
  }

  # Additional data disk
  additional_disks = [
    {
      auto_delete  = false
      disk_size_gb = 500
      disk_type    = "pd-balanced"
      device_name  = "data-disk-1"
      disk_labels = {
        disk_type = "data"
      }
    }
  ]

  network_interfaces = [
    {
      subnetwork         = "projects/my-gcp-project/regions/us-central1/subnetworks/private-subnet"
      subnetwork_project = "my-gcp-project"
      # No external IP
      access_config = []
    }
  ]

  service_account = {
    email = "secure-compute@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  tags = ["private", "secure"]

  labels = {
    security_level = "high"
    compliance     = "pci-dss"
  }
}
```

### Spot VM Example

```hcl
module "spot_instance_template" {
  source = "./gcp/instance-template"

  template_name = "batch-processing"
  environment   = "dev"
  project_id    = "my-gcp-project"

  machine_type         = "n2-standard-8"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # Enable Spot VM
  enable_spot_vm                     = true
  spot_instance_termination_action   = "DELETE"

  network_interfaces = [
    {
      subnetwork = "default"
    }
  ]

  service_account = {
    email = "batch-processor@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  tags = ["batch", "spot"]
}
```

### GPU-Enabled Instance Template

```hcl
module "gpu_instance_template" {
  source = "./gcp/instance-template"

  template_name = "ml-training"
  environment   = "production"
  project_id    = "my-gcp-project"
  region        = "us-central1"

  machine_type         = "n1-standard-8"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # GPU configuration
  guest_accelerators = [
    {
      type  = "nvidia-tesla-t4"
      count = 1
    }
  ]

  # Scheduling for GPU instances
  scheduling = {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = true
  }

  boot_disk = {
    disk_size_gb = 200
    disk_type    = "pd-ssd"
  }

  network_interfaces = [
    {
      subnetwork = "default"
    }
  ]

  service_account = {
    email = "ml-training@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Install NVIDIA drivers
    curl -O https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    # ... additional GPU setup
  EOF

  tags = ["ml", "gpu"]
}
```

### Multi-Project Replication Example

```hcl
provider "google" {
  project = "primary-project"
  region  = "us-central1"
}

provider "google" {
  alias   = "replica"
  project = "replica-project"
  region  = "europe-west1"
}

module "replicated_instance_template" {
  source = "./gcp/instance-template"

  providers = {
    google.replica = google.replica
  }

  template_name = "global-app"
  environment   = "production"
  project_id    = "primary-project"
  region        = "us-central1"

  machine_type         = "e2-standard-4"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  network_interfaces = [
    {
      subnetwork = "projects/primary-project/regions/us-central1/subnetworks/default"
    }
  ]

  service_account = {
    email = "app@primary-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Enable replication
  with_replication    = true
  replica_project_id  = "replica-project"
  replica_region      = "europe-west1"

  replica_network_interfaces = [
    {
      subnetwork = "projects/replica-project/regions/europe-west1/subnetworks/default"
    }
  ]

  labels = {
    multi_region = "true"
  }
}
```

### Confidential Computing Example

```hcl
module "confidential_instance_template" {
  source = "./gcp/instance-template"

  template_name = "confidential-workload"
  environment   = "production"
  project_id    = "my-gcp-project"

  # Confidential Computing requires N2D instance types
  machine_type = "n2d-standard-4"

  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # Enable Confidential Computing
  enable_confidential_computing = true

  # Shielded VM is automatically configured for Confidential VMs
  enable_shielded_vm          = true
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true

  network_interfaces = [
    {
      subnetwork = "default"
    }
  ]

  service_account = {
    email = "confidential@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  tags = ["confidential", "secure"]
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `template_name` | Name of the instance template | `string` |
| `environment` | Environment name (dev, staging, production) | `string` |
| `project_id` | GCP project ID | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `machine_type` | Machine type to use | `string` | `"e2-medium"` |
| `source_image_family` | Source image family | `string` | `null` |
| `source_image_project` | Project with source image | `string` | `null` |
| `enable_shielded_vm` | Enable Shielded VM | `bool` | `true` |
| `enable_secure_boot` | Enable Secure Boot | `bool` | `true` |
| `enable_spot_vm` | Enable Spot VM | `bool` | `false` |
| `enable_confidential_computing` | Enable Confidential Computing | `bool` | `false` |
| `labels` | Labels to apply | `map(string)` | `{}` |

See [variables.tf](./variables.tf) for complete variable documentation.

## Outputs

| Name | Description |
|------|-------------|
| `id` | ID of the instance template |
| `name` | Name of the instance template |
| `self_link` | Self link of the instance template |
| `self_link_unique` | Unique self link (with timestamp) |
| `replica_id` | ID of replica template (if enabled) |
| `replica_self_link` | Self link of replica template (if enabled) |

See [outputs.tf](./outputs.tf) for complete output documentation.

## Security Best Practices

This module implements several security best practices by default:

1. **Shielded VM**: Enabled by default with Secure Boot, vTPM, and Integrity Monitoring
2. **No External IPs**: External IPs must be explicitly configured via access_config
3. **Service Account**: Uses user-specified service account with minimal scopes
4. **Confidential Computing**: Support for encrypted memory for sensitive workloads
5. **Metadata Security**: SSH keys managed via metadata

## Notes

- Template names use `name_prefix` to allow Terraform to create unique names
- Either `source_image` or `source_image_family` should be specified
- Spot VMs cannot use automatic restart and always use TERMINATE for on-host maintenance
- Confidential Computing requires N2D instance types
- GPUs require specific instance types and TERMINATE on host maintenance

## Examples

See the [examples/](./examples/) directory for complete working examples.

## License

This module is released under the MIT License.
