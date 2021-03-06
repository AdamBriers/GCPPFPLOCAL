resource "google_project_service" "project" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_secret_manager_secret" "this" {
  for_each = var.secret
  project   = var.project_id
  secret_id = each.key

  replication {
    user_managed {
      dynamic "replicas" {
        for_each = toset(each.value.secret_location)
        content {
          location = replicas.key
        }
      }
    }
  }

  labels = each.value.secret_labels

  depends_on = [google_project_service.project]
}