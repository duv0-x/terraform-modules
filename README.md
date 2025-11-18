# Terraform Modules Repository

A comprehensive collection of reusable Terraform modules for multi-cloud infrastructure provisioning. This repository follows industry best practices and supports multi-region and multi-account deployments.

## Supported Providers

- **AWS** - Amazon Web Services modules
- **GCP** - Google Cloud Platform modules
- **Kubernetes** - Kubernetes resource modules

## Repository Structure

```
.
├── aws/
│   ├── vpc/              ✅ Complete - Multi-AZ VPC with NAT Gateway
│   ├── ec2/              🚧 Planned
│   ├── eks/              🚧 Planned
│   ├── sqs/              🚧 Planned
│   ├── event-bus/        🚧 Planned
│   ├── lambda/           🚧 Planned
│   ├── dynamo/           🚧 Planned
│   ├── rds/              🚧 Planned
│   ├── event-rules/      🚧 Planned
│   ├── elasticache/      🚧 Planned
│   ├── ecr/              🚧 Planned
│   ├── parameter-store/  🚧 Planned
│   ├── cloudwatch/       🚧 Planned
│   └── s3/               🚧 Planned
├── gcp/
│   ├── vpc/              ✅ Complete - Global VPC with Cloud NAT
│   ├── cloud-functions/  ✅ Complete - Gen 2 Functions
│   ├── compute-engine/   🚧 Planned
│   ├── gke/              🚧 Planned
│   ├── pubsub/           🚧 Planned
│   ├── cloud-storage/    🚧 Planned
│   └── [Other modules]   🚧 Planned
├── kubernetes/
│   └── [K8s modules]     🚧 Planned
└── TEMPLATES/
    └── module-template   ✅ Complete base template
```

## Available Modules

### AWS Modules

| Module | Status | Description | Features |
|--------|--------|-------------|----------|
| **vpc** | ✅ Complete | Multi-AZ VPC with complete networking | Public/private subnets, NAT Gateway, IGW, VPC Flow Logs, VPC Endpoints, Multi-region replication |

### GCP Modules

| Module | Status | Description | Features |
|--------|--------|-------------|----------|
| **vpc** | ✅ Complete | Global VPC with regional subnets | Cloud NAT, Firewall Rules, VPC Peering, Flow Logs, Secondary IP ranges (GKE), Multi-project replication |
| **cloud-functions** | ✅ Complete | Serverless functions (Gen 2) | HTTP/Event triggers, VPC Connector, Secret Manager, Auto-scaling, Multi-region replication |

## Features

- **Multi-Region Support** - Deploy resources across multiple AWS/GCP regions
- **Multi-Account/Multi-Project Support** - Cross-account/project resource provisioning
- **Replication Patterns** - Built-in replication support for stateful services and disaster recovery
- **Best Practices** - Following Terraform and cloud provider best practices
- **Comprehensive Documentation** - Each module includes detailed README with examples
- **Modern Terraform** - Built for Terraform 1.8+ with optional() types and advanced validations

## Requirements

- Terraform >= 1.8.0
- Provider-specific CLI tools (aws-cli, gcloud, kubectl)
- Appropriate cloud credentials configured

## Usage

### Basic Module Usage

```hcl
module "vpc" {
  source = "./aws/vpc"

  vpc_name    = "production-vpc"
  cidr_block  = "10.0.0.0/16"
  environment = "production"

  tags = {
    Project = "MyProject"
    Team    = "Platform"
  }
}
```

### Multi-Region Deployment

```hcl
# Primary region
module "s3_primary" {
  source = "./aws/s3"

  bucket_name       = "my-app-data"
  environment       = "production"
  with_replication  = true
  replication_region = "us-west-2"

  providers = {
    aws.primary     = aws.us-east-1
    aws.destination = aws.us-west-2
  }
}
```

### Multi-Account Deployment

```hcl
# Cross-account setup
module "lambda_cross_account" {
  source = "./aws/lambda"

  function_name           = "cross-account-processor"
  destination_account_id  = "123456789012"

  providers = {
    aws.source      = aws.main-account
    aws.destination = aws.secondary-account
  }
}
```

## Module Standards

All modules in this repository follow these standards:

### File Structure

- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations with descriptions
- `outputs.tf` - Output value definitions
- `versions.tf` - Terraform and provider version constraints
- `README.md` - Module documentation with examples
- `data.tf` - (Optional) Data source lookups
- `locals.tf` - (Optional) Local values and computations
- `iam.tf` - (Optional) IAM roles and policies
- `examples/` - (Optional) Example configurations

### Variable Naming Conventions

- `enable_*` - Boolean flags for feature toggles (e.g., `enable_logging`)
- `with_*` - Configuration enablement (e.g., `with_replication`)
- `is_*` - State checks (e.g., `is_production`)
- Use `snake_case` for all variable names
- Provide descriptions and types for all variables
- Set sensible defaults for optional variables

### Tagging Strategy

All modules support consistent tagging:

```hcl
tags = {
  Name        = "\${var.resource_name}-\${var.environment}"
  Environment = var.environment
  ManagedBy   = "Terraform"
  Module      = "module-name"
}
```

## Testing Modules

Each module can be tested using the examples provided:

```bash
cd aws/vpc/examples/basic
terraform init
terraform plan
terraform apply
terraform destroy
```

## Contributing

When creating new modules:

1. Use the templates in `TEMPLATES/` as a starting point
2. Follow the module standards outlined above
3. Include comprehensive README.md with:
   - Description
   - Usage examples
   - Input variables table
   - Output values table
   - Requirements
4. Add examples in `examples/` directory
5. Test the module before committing
6. Run `terraform fmt -recursive` to format code

## Module Development Workflow

```bash
# Create new module from template
cp -r TEMPLATES/module-template aws/new-service

# Develop your module
cd aws/new-service
# Edit main.tf, variables.tf, outputs.tf, etc.

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Test with example
cd examples/basic
terraform init
terraform plan
```

## Version Constraints

All modules specify minimum versions:

```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

## Security Best Practices

- Never commit sensitive data (`.tfvars`, state files)
- Use AWS Secrets Manager or Parameter Store for secrets
- Enable encryption at rest for all stateful services
- Implement least-privilege IAM policies
- Use private subnets for workloads
- Enable logging and monitoring

## Common Patterns

### Conditional Resource Creation

```hcl
resource "aws_s3_bucket" "replica" {
  count = var.with_replication ? 1 : 0
  # ...
}
```

### Dynamic Blocks for Optional Features

```hcl
dynamic "encryption" {
  for_each = var.enable_encryption ? [1] : []
  content {
    # encryption configuration
  }
}
```

### Tag Merging

```hcl
locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

tags = merge(local.default_tags, var.tags)
```

## Support and Documentation

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform GCP Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform Kubernetes Provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

## License

This repository contains infrastructure code modules for internal use.