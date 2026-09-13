# Apigee X Monitoring Terraform Module

This repository provides a **simple, modular Terraform module** to create Google Cloud Monitoring alerts for Apigee X API proxies.

## Features
- Monitors **latency** and **error rate** for one or more Apigee proxies.
- Configurable **list of proxy names** via a Terraform variable.
- Supports re‑using an existing notification channel **or** creates a new Email notification channel.
- All resources are encapsulated in a single reusable module.

## Repository Layout
```
apigee_monitoring_terraform/
├─ main.tf            # Module implementation
├─ variables.tf       # Input variables definition
├─ outputs.tf         # Exported outputs
└─ README.md          # This file
```

## Prerequisites
- Terraform >= 1.0
- Google Cloud provider configured (see [Google Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs))
- A GCP project with **Monitoring API** enabled.

## Quick Start (Local Only)
1. **Initialize the directory**
   ```bash
   cd /home/jayson/apigee_monitoring_terraform
   terraform init
   ```
2. **Provide a `terraform.tfvars`** (or use `-var` flags) with the required inputs, e.g.:
   ```hcl
   project_id   = "my-gcp-project"
   proxies      = ["proxy-a", "proxy-b"]
   email        = "alerts@example.com"
   # Optional – if you already have a notification channel ID:
   # existing_notification_channel_id = "projects/my-gcp-project/notificationChannels/1234567890"
   ```
3. **Apply the module**
   ```bash
   terraform apply
   ```
   Terraform will create the required alert policies and, if needed, an email notification channel.


## Usage Example
```hcl
module "apigee_monitoring" {
  source                         = "./apigee_monitoring_terraform"
  project_id                     = "my-gcp-project"
  proxies                        = ["orders-api", "inventory-api"]
  email                          = "alerts@example.com"
  # existing_notification_channel_id = "projects/my-gcp-project/notificationChannels/1234567890"
}
```

## Remote State (Optional)

Terraform stores its state file locally in the `.terraform/` directory by default. To keep state centralized and shareable, you can configure a **Google Cloud Storage (GCS) backend**.

```hcl
terraform {
  backend "gcs" {
    bucket  = "my-terraform-state-bucket"
    prefix  = "apigee-monitoring"
  }
}
```

- Create a GCS bucket (e.g., `gsutil mb gs://my-terraform-state-bucket`).
- Grant the service account used by Terraform `storage.objects.create` and `storage.objects.get` permissions.
- Add the above `terraform { backend "gcs" { ... } }` block to the top of `main.tf` (or a separate `backend.tf`).
- Run `terraform init -reconfigure` to migrate the existing local state to the bucket.

Now the state lives in `gs://my-terraform-state-bucket/apigee-monitoring/terraform.tfstate` and is safe for collaborative workflows.

## Understanding the optional notification channel ID

The commented line:

```hcl
# existing_notification_channel_id = "projects/my-gcp-project/notificationChannels/1234567890"
```

is an **optional input variable** that lets you **reuse an existing Google Cloud Monitoring notification channel** instead of creating a new email channel.

- **Leave it empty (default `""`)** – the module creates a new email notification channel using the `email` variable.
- **Provide the full resource name** (`projects/<PROJECT_ID>/notificationChannels/<CHANNEL_ID>`) – the module skips channel creation and attaches the alerts to that existing channel.

### How to obtain the ID

1. **Console**: Go to *Monitoring → Alerting → Notification channels*, select the channel, and copy the ID from the URL (`projects/.../notificationChannels/...`).
2. **CLI**: `gcloud monitoring channels list --project=$PROJECT_ID --format="value(name)"`
3. **API**: `GET https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/notificationChannels`

Add the variable to your `terraform.tfvars` (or pass with `-var`) to reuse the channel.


## Variables
| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_id` | GCP project ID where alerts will be created. | `string` | Yes |
| `proxies` | List of Apigee proxy names to monitor. | `list(string)` | Yes |
| `email` | Email address for alert notifications (used if a new channel is created). | `string` | Yes |
| `existing_notification_channel_id` | (Optional) Fully‑qualified ID of an existing Notification Channel to re‑use. | `string` | No |

## Outputs
| Name | Description |
|------|-------------|
| `notification_channel_id` | ID of the email notification channel used for the alerts. |
| `alert_policy_ids` | List of created alert policy IDs (one per proxy per metric). |

---
**License**: MIT – Feel free to adapt to your needs.

---

