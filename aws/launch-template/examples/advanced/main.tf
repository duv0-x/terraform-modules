provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "destination"
  region = "us-west-2"
}

module "advanced_launch_template" {
  source = "../../"

  providers = {
    aws.destination = aws.destination
  }

  template_name = "advanced-app"
  environment   = "production"
  description   = "Advanced launch template with instance requirements and replication"

  image_id = "ami-0c55b159cbfafe1f0"

  # Use attribute-based instance type selection
  instance_requirements = {
    vcpu_count = {
      min = 4
      max = 8
    }
    memory_mib = {
      min = 8192
      max = 16384
    }
    cpu_manufacturers    = ["intel", "amd"]
    instance_generations = ["current"]
  }

  key_name = "production-key"

  # Advanced monitoring and security
  enable_monitoring              = true
  enable_imdsv2                  = true
  enable_ebs_optimization        = true
  enable_termination_protection  = false

  # IAM instance profile
  iam_instance_profile = {
    name = "app-instance-profile"
  }

  # Network configuration
  network_interfaces = [
    {
      device_index                = 0
      associate_public_ip_address = false
      delete_on_termination       = true
      security_groups             = ["sg-0123456789abcdef0"]
      subnet_id                   = "subnet-0123456789abcdef0"
    }
  ]

  # Block device configuration
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 125
        encrypted             = true
        kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abc-123"
        delete_on_termination = true
      }
    },
    {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = 500
        volume_type           = "gp3"
        iops                  = 5000
        throughput            = 250
        encrypted             = true
        kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abc-123"
        delete_on_termination = false
      }
    }
  ]

  # Placement configuration
  placement = {
    tenancy = "default"
  }

  # User data
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install CloudWatch agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm

    # Install application dependencies
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    # Configure logging
    mkdir -p /var/log/app

    echo "Instance initialized successfully"
  EOF

  # Multi-region replication
  with_replication = true

  replica_image_id               = "ami-0987654321fedcba0" # Different AMI for west region
  replica_vpc_security_group_ids = ["sg-west-0123456789"]

  replica_network_interfaces = [
    {
      device_index                = 0
      associate_public_ip_address = false
      delete_on_termination       = true
      security_groups             = ["sg-west-0123456789"]
      subnet_id                   = "subnet-west-0123456789"
    }
  ]

  replica_key_name = "production-key-west"

  # Tags
  tags = {
    Application = "ProductionApp"
    CostCenter  = "Engineering"
    Compliance  = "HIPAA"
    Backup      = "Daily"
  }

  tag_specifications = ["instance", "volume", "network-interface"]
}

output "primary_template_id" {
  description = "Primary launch template ID"
  value       = module.advanced_launch_template.id
}

output "primary_template_arn" {
  description = "Primary launch template ARN"
  value       = module.advanced_launch_template.arn
}

output "replica_template_id" {
  description = "Replica launch template ID"
  value       = module.advanced_launch_template.replica_id
}

output "replica_template_arn" {
  description = "Replica launch template ARN"
  value       = module.advanced_launch_template.replica_arn
}