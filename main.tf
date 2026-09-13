terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  # region can be omitted for monitoring resources
}

# Optional email notification channel (created only when not reusing an existing one)
resource "google_monitoring_notification_channel" "email_channel" {
  count = var.existing_notification_channel_id == "" ? 1 : 0

  display_name = "Apigee Monitoring Alerts"
  type         = "email"
  labels = {
    email_address = var.email
  }
}

# Local value to resolve which notification channel ID to use
locals {
  notification_channel_id = var.existing_notification_channel_id != "" ? var.existing_notification_channel_id : google_monitoring_notification_channel.email_channel[0].id
}

# Create alert policies for each proxy and each metric
resource "google_monitoring_alert_policy" "proxy_latency" {
  for_each = toset(var.proxies)

  display_name = "Apigee Proxy ${each.key} Latency"
  combiner    = "OR"

  conditions {
    display_name = "Latency > 500ms"
    condition_threshold {
      filter          = "metric.type=\"apigee.googleapis.com/proxy/latencies\" AND resource.type=\"apigee.googleapis.com/Proxy\" AND metric.labels.proxy_name=\"${each.key}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 500
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [local.notification_channel_id]
}

resource "google_monitoring_alert_policy" "proxy_error_rate" {
  for_each = toset(var.proxies)

  display_name = "Apigee Proxy ${each.key} Error Rate"
  combiner    = "OR"

  conditions {
    display_name = "Error rate > 5%"
    condition_threshold {
      filter          = "metric.type=\"apigee.googleapis.com/proxy/response_count\" AND resource.type=\"apigee.googleapis.com/Proxy\" AND metric.labels.response_code_class=\"4xx\" AND metric.labels.proxy_name=\"${each.key}\""
      comparison      = "COMPARISON_GT"
      # Approximate error count threshold; for a real ratio use a metric that provides a percentage.
      threshold_value = 5
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
        group_by_fields    = ["metric.labels.response_code_class"]
      }
    }
  }

  notification_channels = [local.notification_channel_id]
}
