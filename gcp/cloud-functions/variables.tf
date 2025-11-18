# Core configuration
variable "function_name" {
  description = "Name of the Cloud Function"
  type        = string

  validation {
    condition     = length(var.function_name) > 0 && length(var.function_name) <= 63
    error_message = "Function name must be between 1 and 63 characters."
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID is required."
  }
}

variable "region" {
  description = "GCP region for the Cloud Function"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "description" {
  description = "Description of the Cloud Function"
  type        = string
  default     = ""
}

# Runtime configuration
variable "runtime" {
  description = "Runtime for the Cloud Function (e.g., python310, nodejs18, go119)"
  type        = string
  default     = "python310"
}

variable "entry_point" {
  description = "Name of the function to execute (entry point)"
  type        = string
}

variable "available_memory_mb" {
  description = "Memory available for the function in MB"
  type        = number
  default     = 256

  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 4096, 8192], var.available_memory_mb)
    error_message = "Memory must be one of: 128, 256, 512, 1024, 2048, 4096, 8192 MB."
  }
}

variable "timeout" {
  description = "Timeout for the function in seconds (max 540)"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 540
    error_message = "Timeout must be between 1 and 540 seconds."
  }
}

variable "max_instances" {
  description = "Maximum number of function instances"
  type        = number
  default     = 100
}

variable "min_instances" {
  description = "Minimum number of function instances (0 = scale to zero)"
  type        = number
  default     = 0
}

# Source code configuration
variable "source_archive_bucket" {
  description = "GCS bucket containing the function source code archive"
  type        = string
}

variable "source_archive_object" {
  description = "GCS object name of the function source code archive"
  type        = string
}

# Trigger configuration
variable "trigger_http" {
  description = "Enable HTTP trigger for the function"
  type        = bool
  default     = true
}

variable "https_trigger_security_level" {
  description = "Security level for HTTPS trigger (SECURE_ALWAYS or SECURE_OPTIONAL)"
  type        = string
  default     = "SECURE_ALWAYS"

  validation {
    condition     = contains(["SECURE_ALWAYS", "SECURE_OPTIONAL"], var.https_trigger_security_level)
    error_message = "Must be SECURE_ALWAYS or SECURE_OPTIONAL."
  }
}

variable "event_trigger" {
  description = "Event trigger configuration (alternative to HTTP trigger)"
  type = object({
    event_type = string
    resource   = string
    service    = optional(string, "")
    failure_policy = optional(object({
      retry = bool
    }), null)
  })
  default = null
}

# Environment and secrets
variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "secret_environment_variables" {
  description = "Secret environment variables from Secret Manager"
  type = list(object({
    key        = string
    project_id = optional(string, "")
    secret     = string
    version    = string
  }))
  default   = []
  sensitive = true
}

# Networking
variable "vpc_connector" {
  description = "VPC connector for private VPC access"
  type        = string
  default     = ""
}

variable "vpc_connector_egress_settings" {
  description = "Egress settings for VPC connector (ALL_TRAFFIC, PRIVATE_RANGES_ONLY)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_connector_egress_settings)
    error_message = "Must be ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }
}

variable "ingress_settings" {
  description = "Ingress settings (ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB)"
  type        = string
  default     = "ALLOW_ALL"

  validation {
    condition     = contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], var.ingress_settings)
    error_message = "Must be ALLOW_ALL, ALLOW_INTERNAL_ONLY, or ALLOW_INTERNAL_AND_GCLB."
  }
}

# IAM and permissions
variable "enable_public_access" {
  description = "Allow unauthenticated public access to the function"
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "List of members who can invoke the function (e.g., user:email@example.com, serviceAccount:sa@project.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}

variable "service_account_email" {
  description = "Service account email for the function. If empty, uses default compute service account"
  type        = string
  default     = ""
}

# Build configuration
variable "build_environment_variables" {
  description = "Environment variables available during build time"
  type        = map(string)
  default     = {}
}

variable "docker_repository" {
  description = "Docker repository for the function container image"
  type        = string
  default     = ""
}

# Multi-region replication
variable "with_replication" {
  description = "Create replica function in another region"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region for function replication"
  type        = string
  default     = ""
}

# Labels
variable "labels" {
  description = "Labels to apply to the function"
  type        = map(string)
  default     = {}
}
