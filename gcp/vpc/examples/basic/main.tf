# Basic GCP VPC example

provider "google" {
  project = "my-gcp-project-id"
  region  = "us-central1"
}

module "vpc" {
  source = "../.."

  project_id   = "my-gcp-project-id"
  network_name = "example-vpc"
  environment  = "dev"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "subnet-us-central1"
      subnet_ip             = "10.0.1.0/24"
      subnet_region         = "us-central1"
      enable_private_access = true
      enable_flow_logs      = false
    },
    {
      subnet_name           = "subnet-us-east1"
      subnet_ip             = "10.0.2.0/24"
      subnet_region         = "us-east1"
      enable_private_access = true
      enable_flow_logs      = false
    }
  ]

  enable_cloud_nat = true

  labels = {
    project = "example"
    team    = "devops"
  }
}

# Outputs
output "network_id" {
  value = module.vpc.network_id
}

output "network_name" {
  value = module.vpc.network_name
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "subnet_names" {
  value = module.vpc.subnet_names
}
