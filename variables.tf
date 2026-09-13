variable "project_id" {
  description = "GCP project ID where alert policies will be created."
  type        = string
}

variable "proxies" {
  description = "List of Apigee proxy names to monitor."
  type        = list(string)
}

variable "email" {
  description = "Email address for alert notifications (used when creating a new channel)."
  type        = string
}

variable "existing_notification_channel_id" {
  description = "Fully-qualified ID of an existing Notification Channel to reuse. Leave empty to create a new email channel."
  type        = string
  default     = ""
}
