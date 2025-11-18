# Basic Cloud Function example

provider "google" {
  project = "my-gcp-project-id"
  region  = "us-central1"
}

module "function" {
  source = "../.."

  project_id    = "my-gcp-project-id"
  function_name = "hello-world"
  region        = "us-central1"
  environment   = "dev"

  runtime     = "python310"
  entry_point = "hello_http"

  source_archive_bucket = "my-function-source-bucket"
  source_archive_object = "hello-world.zip"

  trigger_http         = true
  enable_public_access = true

  available_memory_mb = 256
  timeout             = 60

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  labels = {
    app  = "hello"
    team = "dev"
  }
}

# Outputs
output "function_url" {
  description = "URL to invoke the function"
  value       = module.function.function_url
}

output "function_name" {
  value = module.function.function_name
}
