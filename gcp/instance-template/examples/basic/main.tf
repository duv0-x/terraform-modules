provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
}

module "basic_instance_template" {
  source = "../../"

  template_name = "basic-web-server"
  environment   = "dev"
  project_id    = "my-gcp-project"
  region        = "us-central1"

  machine_type         = "e2-medium"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"

  # Boot disk configuration
  boot_disk = {
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  # Network configuration
  network_interfaces = [
    {
      subnetwork         = "projects/my-gcp-project/regions/us-central1/subnetworks/default"
      subnetwork_project = "my-gcp-project"
      # Enable external IP
      access_config = [
        {
          network_tier = "PREMIUM"
        }
      ]
    }
  ]

  # Service account
  service_account = {
    email = "compute@my-gcp-project.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  # Startup script
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install web server
    apt-get install -y nginx

    # Start and enable nginx
    systemctl start nginx
    systemctl enable nginx

    # Create simple index page
    echo "<h1>Hello from GCP Instance Template</h1>" > /var/www/html/index.html
  EOF

  # Network tags for firewall rules
  tags = ["web", "http-server", "https-server"]

  # Labels
  labels = {
    application = "webapp"
    team        = "devops"
    cost_center = "engineering"
  }
}

output "instance_template_id" {
  description = "ID of the instance template"
  value       = module.basic_instance_template.id
}

output "instance_template_name" {
  description = "Name of the instance template"
  value       = module.basic_instance_template.name
}

output "instance_template_self_link" {
  description = "Self link of the instance template"
  value       = module.basic_instance_template.self_link
}
