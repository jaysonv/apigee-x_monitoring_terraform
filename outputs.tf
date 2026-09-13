output "notification_channel_id" {
  description = "ID of the email notification channel used for the alerts."
  value       = local.notification_channel_id
}

output "alert_policy_ids" {
  description = "List of created alert policy IDs (one per proxy per metric)."
  value = concat(
    [for p in google_monitoring_alert_policy.proxy_latency : p.id],
    [for p in google_monitoring_alert_policy.proxy_error_rate : p.id]
  )
}
