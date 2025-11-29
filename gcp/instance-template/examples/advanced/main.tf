provider "google" {
  project = "primary-project"
  region  = "us-central1"
}

provider "google" {
  alias   = "replica"
  project = "replica-project"
  region  = "europe-west1"
}

module "advanced_instance_template" {
  source = "../../"

  providers = {
    google.replica = google.replica
  }

  template_name = "advanced-secure-app"
  environment   = "production"
  project_id    = "primary-project"
  region        = "us-central1"
  description   = "Advanced instance template with Shielded VM, custom disks, and replication"

  # Machine configuration
  machine_type = "n2-standard-8"

  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # Shielded VM configuration
  enable_shielded_vm          = true
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true

  # Boot disk with SSD
  boot_disk = {
    auto_delete  = true
    disk_size_gb = 100
    disk_type    = "pd-ssd"
    disk_labels = {
      disk_type = "boot"
      encrypted = "true"
    }
  }

  # Additional data disks
  additional_disks = [
    {
      auto_delete  = false
      disk_size_gb = 500
      disk_type    = "pd-balanced"
      device_name  = "data-disk-1"
      disk_labels = {
        disk_type = "data"
        purpose   = "database"
      }
    },
    {
      auto_delete  = true
      disk_size_gb = 100
      disk_type    = "pd-ssd"
      device_name  = "cache-disk-1"
      disk_labels = {
        disk_type = "cache"
        purpose   = "temporary"
      }
    }
  ]

  # Private network configuration
  network_interfaces = [
    {
      subnetwork         = "projects/primary-project/regions/us-central1/subnetworks/private-subnet"
      subnetwork_project = "primary-project"
      # No external IP for security
      access_config = []
    }
  ]

  # Service account with minimal permissions
  service_account = {
    email = "secure-app@primary-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Advanced machine features
  advanced_machine_features = {
    enable_nested_virtualization = false
    threads_per_core             = 2
  }

  # Minimum CPU platform
  min_cpu_platform = "Intel Cascade Lake"

  # Scheduling configuration
  scheduling = {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  # Startup script
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install monitoring agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install

    # Install Docker
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Format and mount data disk
    if [ ! -d "/mnt/data" ]; then
      mkdir -p /mnt/data
      mkfs.ext4 -F /dev/disk/by-id/google-data-disk-1
      mount /dev/disk/by-id/google-data-disk-1 /mnt/data
      echo '/dev/disk/by-id/google-data-disk-1 /mnt/data ext4 defaults 0 2' >> /etc/fstab
    fi

    # Configure logging
    mkdir -p /var/log/app
    touch /var/log/app/application.log

    echo "Instance initialization completed successfully"
  EOF

  # SSH keys
  enable_ssh_keys_metadata = true
  ssh_keys = [
    "admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... admin@example.com",
    "deploy:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... deploy@example.com"
  ]

  # Additional metadata
  metadata = {
    enable-oslogin        = "TRUE"
    enable-oslogin-2fa    = "TRUE"
    block-project-ssh-keys = "FALSE"
  }

  # Network tags
  tags = ["private", "secure", "production", "app-tier"]

  # Multi-project replication
  with_replication   = true
  replica_project_id = "replica-project"
  replica_region     = "europe-west1"

  replica_source_image_family = "ubuntu-2204-lts"

  replica_network_interfaces = [
    {
      subnetwork         = "projects/replica-project/regions/europe-west1/subnetworks/private-subnet"
      subnetwork_project = "replica-project"
      access_config      = []
    }
  ]

  replica_metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Same initialization as primary
    apt-get update
    apt-get upgrade -y

    # Install monitoring agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install

    echo "Replica instance initialization completed successfully"
  EOF

  # Labels
  labels = {
    application    = "production-app"
    team           = "platform"
    cost_center    = "engineering"
    compliance     = "pci-dss"
    backup         = "daily"
    multi_region   = "true"
    security_level = "high"
  }
}

output "primary_template_id" {
  description = "Primary instance template ID"
  value       = module.advanced_instance_template.id
}

output "primary_template_name" {
  description = "Primary instance template name"
  value       = module.advanced_instance_template.name
}

output "primary_template_self_link" {
  description = "Primary instance template self link"
  value       = module.advanced_instance_template.self_link
}

output "replica_template_id" {
  description = "Replica instance template ID"
  value       = module.advanced_instance_template.replica_id
}

output "replica_template_name" {
  description = "Replica instance template name"
  value       = module.advanced_instance_template.replica_name
}

output "replica_template_self_link" {
  description = "Replica instance template self link"
  value       = module.advanced_instance_template.replica_self_link
}
