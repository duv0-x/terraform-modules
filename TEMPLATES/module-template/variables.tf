# Core variables
variable "resource_name" {
  description = "Name of the resource to create"
  type        = string

  validation {
    condition     = length(var.resource_name) > 0 && length(var.resource_name) <= 64
    error_message = "Resource name must be between 1 and 64 characters."
  }
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

# Feature flags
variable "enable_optional_feature" {
  description = "Enable optional feature configuration"
  type        = bool
  default     = false
}

# Replication configuration
variable "with_replication" {
  description = "Enable replication to a secondary region/account"
  type        = bool
  default     = false
}

variable "replication_region" {
  description = "AWS region for replication (required if with_replication is true)"
  type        = string
  default     = ""
}

variable "destination_account_id" {
  description = "Destination AWS account ID for cross-account replication"
  type        = string
  default     = ""
}

# Tagging
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Optional: Advanced configuration
variable "advanced_config" {
  description = "Advanced configuration options"
  type = object({
    setting1 = optional(string, "default_value")
    setting2 = optional(number, 100)
    setting3 = optional(bool, true)
  })
  default = {}
}
