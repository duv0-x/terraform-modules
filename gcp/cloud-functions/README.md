# GCP Cloud Functions Terraform Module

## Description

This module creates Google Cloud Functions (Gen 2) with support for HTTP triggers, event triggers, VPC connectivity, secret management, and multi-region replication.

## Features

- **Cloud Functions Gen 2** - Latest generation with improved performance
- **Multiple Runtimes** - Python, Node.js, Go, Java, .NET, Ruby, PHP
- **HTTP & Event Triggers** - HTTP endpoints or event-driven execution
- **VPC Connectivity** - Private VPC access via VPC Connector
- **Secret Management** - Integration with Secret Manager
- **IAM Control** - Fine-grained access control
- **Auto-scaling** - Min/max instance configuration
- **Multi-Region** - Replica functions for high availability
- **Environment Variables** - Runtime and build-time configuration
- **Custom Service Accounts** - Dedicated service account support

## Usage

### Basic HTTP Function

```hcl
module "http_function" {
  source = "../../gcp/cloud-functions"

  project_id   = "my-gcp-project"
  function_name = "my-http-function"
  region        = "us-central1"
  environment   = "production"

  runtime     = "python310"
  entry_point = "main"

  source_archive_bucket = "my-function-source-bucket"
  source_archive_object = "function-source.zip"

  trigger_http         = true
  enable_public_access = true

  available_memory_mb = 256
  timeout             = 60
  max_instances       = 10

  labels = {
    app = "myapp"
  }
}
```

### Function with Pub/Sub Trigger

```hcl
module "pubsub_function" {
  source = "../../gcp/cloud-functions"

  project_id    = "my-gcp-project"
  function_name = "pubsub-processor"
  region        = "us-central1"
  environment   = "production"

  runtime     = "nodejs18"
  entry_point = "processPubSubMessage"

  source_archive_bucket = "my-function-source-bucket"
  source_archive_object = "pubsub-function.zip"

  trigger_http = false
  event_trigger = {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    resource   = "projects/my-gcp-project/topics/my-topic"
    failure_policy = {
      retry = true
    }
  }

  available_memory_mb = 512
  timeout             = 120

  labels = {
    trigger = "pubsub"
  }
}
```

### Function with VPC Access and Secrets

```hcl
module "vpc_function" {
  source = "../../gcp/cloud-functions"

  project_id    = "my-gcp-project"
  function_name = "vpc-function"
  region        = "us-central1"
  environment   = "production"

  runtime     = "python310"
  entry_point = "main"

  source_archive_bucket = "my-function-source-bucket"
  source_archive_object = "function.zip"

  trigger_http = true
  invoker_members = [
    "serviceAccount:backend-sa@my-project.iam.gserviceaccount.com"
  ]

  # VPC connectivity
  vpc_connector                 = "projects/my-project/locations/us-central1/connectors/my-connector"
  vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  ingress_settings              = "ALLOW_INTERNAL_ONLY"

  # Environment variables
  environment_variables = {
    DATABASE_HOST = "10.0.1.5"
    APP_ENV       = "production"
  }

  # Secrets from Secret Manager
  secret_environment_variables = [
    {
      key     = "DATABASE_PASSWORD"
      secret  = "db-password"
      version = "latest"
    },
    {
      key     = "API_KEY"
      secret  = "api-key"
      version = "1"
    }
  ]

  service_account_email = "function-sa@my-project.iam.gserviceaccount.com"

  available_memory_mb = 1024
  timeout             = 300
  min_instances       = 1
  max_instances       = 50

  labels = {
    vpc_enabled = "true"
  }
}
```

### Multi-Region Function

```hcl
provider "google" {
  alias  = "primary"
  project = "my-gcp-project"
  region  = "us-central1"
}

provider "google" {
  alias   = "dr"
  project = "my-gcp-project"
  region  = "us-east1"
}

module "multi_region_function" {
  source = "../../gcp/cloud-functions"

  project_id    = "my-gcp-project"
  function_name = "resilient-function"
  region        = "us-central1"
  environment   = "production"

  runtime     = "python310"
  entry_point = "handler"

  source_archive_bucket = "my-function-source-bucket"
  source_archive_object = "function.zip"

  trigger_http         = true
  enable_public_access = false
  invoker_members      = ["serviceAccount:invoker@my-project.iam.gserviceaccount.com"]

  # Multi-region replication
  with_replication = true
  replica_region   = "us-east1"

  providers = {
    google         = google.primary
    google.replica = google.dr
  }

  available_memory_mb = 512
  max_instances       = 20

  labels = {
    ha_enabled = "true"
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| function_name | Name of the Cloud Function | `string` | n/a | yes |
| project_id | GCP Project ID | `string` | n/a | yes |
| region | GCP region | `string` | `"us-central1"` | no |
| runtime | Function runtime | `string` | `"python310"` | no |
| entry_point | Function entry point | `string` | n/a | yes |
| source_archive_bucket | GCS bucket with source code | `string` | n/a | yes |
| source_archive_object | GCS object name | `string` | n/a | yes |
| trigger_http | Enable HTTP trigger | `bool` | `true` | no |
| event_trigger | Event trigger configuration | `object` | `null` | no |
| available_memory_mb | Memory in MB | `number` | `256` | no |
| timeout | Timeout in seconds | `number` | `60` | no |
| max_instances | Maximum instances | `number` | `100` | no |
| min_instances | Minimum instances | `number` | `0` | no |
| environment_variables | Environment variables | `map(string)` | `{}` | no |
| secret_environment_variables | Secret variables | `list(object)` | `[]` | no |
| vpc_connector | VPC connector | `string` | `""` | no |
| enable_public_access | Allow public access | `bool` | `false` | no |
| with_replication | Enable replication | `bool` | `false` | no |
| replica_region | Replica region | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_id | Function ID |
| function_name | Function name |
| function_url | HTTPS URL for invocation |
| function_region | Deployment region |
| replica_function_id | Replica function ID |
| replica_function_url | Replica function URL |

## Supported Runtimes

- Python: `python38`, `python39`, `python310`, `python311`, `python312`
- Node.js: `nodejs16`, `nodejs18`, `nodejs20`
- Go: `go116`, `go118`, `go119`, `go121`
- Java: `java11`, `java17`
- .NET: `dotnet3`, `dotnet6`
- Ruby: `ruby30`, `ruby32`
- PHP: `php81`, `php82`

## Cost Considerations

- **Invocations**: $0.40 per million invocations
- **Compute Time**: $0.0000025 per GB-second
- **Networking**: Egress charges apply
- **Min Instances**: Keep at 0 to avoid idle charges
- **VPC Connector**: Additional hourly charge

## Best Practices

1. **Memory**: Right-size memory (128MB-8192MB)
2. **Timeout**: Set realistic timeouts (max 540s)
3. **Secrets**: Use Secret Manager, not env vars
4. **Service Account**: Use dedicated SA with least privilege
5. **Min Instances**: Set > 0 for latency-sensitive workloads
6. **VPC Connector**: Use for private resource access
7. **Monitoring**: Enable Cloud Logging and Monitoring

## License

Internal use only.
