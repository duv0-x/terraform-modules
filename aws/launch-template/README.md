# AWS Launch Template Module

Terraform module to create and manage AWS EC2 Launch Templates with comprehensive configuration options and multi-region replication support.

## Features

- **Modern Security Defaults**: IMDSv2 enabled by default, EBS encryption by default
- **Flexible Instance Selection**: Support for both fixed instance types and attribute-based selection
- **Multi-Region Replication**: Built-in support for cross-region launch template replication
- **Comprehensive Monitoring**: CloudWatch detailed monitoring enabled by default
- **Advanced Networking**: Support for multiple network interfaces and security configurations
- **Latest AWS Features**: Support for Nitro Enclaves, capacity reservations, and more
- **Terraform 1.8+ Features**: Uses optional attributes and advanced validations

## Requirements

- Terraform >= 1.8.0
- AWS Provider >= 5.0

## Usage

### Basic Example

```hcl
module "launch_template" {
  source = "./aws/launch-template"

  template_name = "web-server"
  environment   = "production"
  description   = "Launch template for web servers"

  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  vpc_security_group_ids = ["sg-12345678"]

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello World"
  EOF

  tags = {
    Project = "MyApp"
  }
}
```

### Advanced Example with Instance Requirements

```hcl
module "launch_template_flexible" {
  source = "./aws/launch-template"

  template_name = "flexible-compute"
  environment   = "production"

  image_id = "ami-0c55b159cbfafe1f0"

  # Use attribute-based instance type selection
  instance_requirements = {
    vcpu_count = {
      min = 2
      max = 4
    }
    memory_mib = {
      min = 4096
      max = 8192
    }
    cpu_manufacturers    = ["intel", "amd"]
    instance_generations = ["current"]
  }

  enable_monitoring = true
  enable_imdsv2     = true

  iam_instance_profile = {
    name = "my-instance-profile"
  }

  network_interfaces = [
    {
      device_index                = 0
      associate_public_ip_address = false
      delete_on_termination       = true
      security_groups             = ["sg-12345678"]
      subnet_id                   = "subnet-12345678"
    }
  ]

  tags = {
    CostCenter = "Engineering"
  }
}
```

### Multi-Region Replication Example

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "destination"
  region = "us-west-2"
}

module "launch_template_replicated" {
  source = "./aws/launch-template"

  providers = {
    aws.destination = aws.destination
  }

  template_name = "replicated-app"
  environment   = "production"

  image_id      = "ami-east-123456"
  instance_type = "t3.medium"

  vpc_security_group_ids = ["sg-east-12345"]

  # Enable replication
  with_replication = true

  # Replica-specific configuration
  replica_image_id               = "ami-west-123456"
  replica_vpc_security_group_ids = ["sg-west-12345"]

  tags = {
    MultiRegion = "true"
  }
}
```

### Example with Nitro Enclaves

```hcl
module "enclave_template" {
  source = "./aws/launch-template"

  template_name = "enclave-app"
  environment   = "production"

  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.xlarge" # Enclave-enabled instance type

  enable_enclave = true

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 50
        volume_type = "gp3"
        encrypted   = true
        kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/abc123"
      }
    }
  ]
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `template_name` | Name of the launch template | `string` |
| `environment` | Environment name (dev, staging, production) | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `description` | Description of the launch template | `string` | `null` |
| `image_id` | AMI ID to use for instances | `string` | `null` |
| `instance_type` | Instance type to use | `string` | `null` |
| `key_name` | Key pair name for SSH access | `string` | `null` |
| `enable_monitoring` | Enable detailed CloudWatch monitoring | `bool` | `true` |
| `enable_imdsv2` | Enable IMDSv2 for enhanced security | `bool` | `true` |
| `enable_ebs_optimization` | Enable EBS optimization | `bool` | `true` |
| `enable_termination_protection` | Enable instance termination protection | `bool` | `false` |
| `vpc_security_group_ids` | List of security group IDs | `list(string)` | `[]` |
| `tags` | Additional tags | `map(string)` | `{}` |

See [variables.tf](./variables.tf) for complete variable documentation.

## Outputs

| Name | Description |
|------|-------------|
| `id` | ID of the launch template |
| `arn` | ARN of the launch template |
| `name` | Name of the launch template |
| `latest_version` | Latest version of the launch template |
| `replica_id` | ID of the replica launch template (if enabled) |
| `replica_arn` | ARN of the replica launch template (if enabled) |

See [outputs.tf](./outputs.tf) for complete output documentation.

## Security Best Practices

This module implements several security best practices by default:

1. **IMDSv2 Required**: Instance Metadata Service Version 2 is enabled by default for enhanced security
2. **EBS Encryption**: Block devices are encrypted by default
3. **No Public IPs**: Public IP association must be explicitly enabled
4. **Secure Metadata**: Metadata hop limit set to 1 by default
5. **Monitoring Enabled**: CloudWatch detailed monitoring enabled by default

## Notes

- Either `instance_type` or `instance_requirements` must be specified, but not both
- When using `network_interfaces`, do not specify `vpc_security_group_ids` at the root level
- User data will be automatically base64-encoded unless using `user_data_base64`
- Tag specifications apply to instances, volumes, and network interfaces by default

## Examples

See the [examples/](./examples/) directory for complete working examples.

## License

This module is released under the MIT License.