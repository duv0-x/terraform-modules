################################################################################
# Cloud Function (Gen 2)
################################################################################

resource "google_cloudfunctions2_function" "this" {
  project  = var.project_id
  name     = local.function_full_name
  location = var.region

  description = var.description != "" ? var.description : "Cloud Function for ${var.environment}"
  labels      = local.common_labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = var.source_archive_bucket
        object = var.source_archive_object
      }
    }

    environment_variables = var.build_environment_variables
    docker_repository     = var.docker_repository != "" ? var.docker_repository : null
  }

  service_config {
    available_memory   = "${var.available_memory_mb}M"
    timeout_seconds    = var.timeout
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances

    environment_variables    = var.environment_variables
    service_account_email    = local.service_account
    ingress_settings         = var.ingress_settings
    all_traffic_on_latest_revision = true

    # VPC connector
    vpc_connector                 = local.has_vpc_connector ? var.vpc_connector : null
    vpc_connector_egress_settings = local.has_vpc_connector ? var.vpc_connector_egress_settings : null

    # Secret environment variables
    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables
      content {
        key        = secret_environment_variables.value.key
        project_id = secret_environment_variables.value.project_id != "" ? secret_environment_variables.value.project_id : var.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
  }

  # Event trigger (Pub/Sub, Storage, etc.)
  dynamic "event_trigger" {
    for_each = local.is_event_trigger ? [var.event_trigger] : []
    content {
      event_type            = event_trigger.value.event_type
      pubsub_topic          = event_trigger.value.resource
      service_account_email = local.service_account

      dynamic "retry_policy" {
        for_each = event_trigger.value.failure_policy != null ? [event_trigger.value.failure_policy] : []
        content {
          retry_policy = retry_policy.value.retry ? "RETRY_POLICY_RETRY" : "RETRY_POLICY_DO_NOT_RETRY"
        }
      }
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

################################################################################
# IAM Policy for Function Invocation
################################################################################

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  for_each = toset(local.invoker_members)

  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.this.name
  role           = "roles/cloudfunctions.invoker"
  member         = each.value
}

################################################################################
# Replica Cloud Function (Multi-Region)
################################################################################

resource "google_cloudfunctions2_function" "replica" {
  count    = local.has_replication ? 1 : 0
  provider = google.replica

  project  = var.project_id
  name     = "${local.function_full_name}-replica"
  location = var.replica_region

  description = "Replica of ${local.function_full_name}"
  labels = merge(
    local.common_labels,
    {
      replica_of = local.function_full_name
    }
  )

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = var.source_archive_bucket
        object = var.source_archive_object
      }
    }

    environment_variables = var.build_environment_variables
    docker_repository     = var.docker_repository != "" ? var.docker_repository : null
  }

  service_config {
    available_memory   = "${var.available_memory_mb}M"
    timeout_seconds    = var.timeout
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances

    environment_variables         = var.environment_variables
    service_account_email         = local.service_account
    ingress_settings              = var.ingress_settings
    all_traffic_on_latest_revision = true

    vpc_connector                 = local.has_vpc_connector ? var.vpc_connector : null
    vpc_connector_egress_settings = local.has_vpc_connector ? var.vpc_connector_egress_settings : null

    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables
      content {
        key        = secret_environment_variables.value.key
        project_id = secret_environment_variables.value.project_id != "" ? secret_environment_variables.value.project_id : var.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
  }

  dynamic "event_trigger" {
    for_each = local.is_event_trigger ? [var.event_trigger] : []
    content {
      event_type            = event_trigger.value.event_type
      pubsub_topic          = event_trigger.value.resource
      service_account_email = local.service_account

      dynamic "retry_policy" {
        for_each = event_trigger.value.failure_policy != null ? [event_trigger.value.failure_policy] : []
        content {
          retry_policy = retry_policy.value.retry ? "RETRY_POLICY_RETRY" : "RETRY_POLICY_DO_NOT_RETRY"
        }
      }
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

# Replica IAM
resource "google_cloudfunctions2_function_iam_member" "replica_invoker" {
  for_each = local.has_replication ? toset(local.invoker_members) : []
  provider = google.replica

  project        = var.project_id
  location       = var.replica_region
  cloud_function = google_cloudfunctions2_function.replica[0].name
  role           = "roles/cloudfunctions.invoker"
  member         = each.value
}
