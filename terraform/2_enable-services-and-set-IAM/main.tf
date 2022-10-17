terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }
}

# enable required services in CICD project
resource "google_project_service" "sourcerepo" {
  project = var.project_cicd
  service = "sourcerepo.googleapis.com"
}
resource "google_project_service" "cloudbuild" {
  project = var.project_cicd
  service = "cloudbuild.googleapis.com"
}
resource "google_project_service" "artifactregistry" {
  project = var.project_cicd
  service = "artifactregistry.googleapis.com"
}
resource "google_project_service" "containerscanning" {
  project = var.project_cicd
  service = "containerscanning.googleapis.com"
}
resource "google_project_service" "servicenetworking" {
  project = var.project_cicd
  service = "servicenetworking.googleapis.com"
}
resource "google_project_service" "clouddeploy" {
  project = var.project_cicd
  service = "clouddeploy.googleapis.com"
}
resource "google_project_service" "cloudresourcemanager" {
  project = var.project_cicd
  service = "cloudresourcemanager.googleapis.com"
}
resource "google_project_service" "gkehub" {
  project = var.project_cicd
  service = "gkehub.googleapis.com"
}
resource "google_project_service" "serviceusage" {
  project = var.project_cicd
  service = "serviceusage.googleapis.com"
}
resource "google_project_service" "connectgateway" {
  project = var.project_cicd
  service = "connectgateway.googleapis.com"
}
resource "google_project_service" "anthos" {
  project = var.project_cicd
  service = "anthos.googleapis.com"
}
resource "google_project_service" "gkeconnect" {
  project = var.project_cicd
  service = "gkeconnect.googleapis.com"
}

# create service accounts for Cloud Build and Cloud Deploy
resource "google_service_account" "cloudbuild" {
  project      = var.project_cicd
  account_id   = var.service_account_cloudbuild_name
  display_name = var.service_account_cloudbuild_name
}
resource "google_service_account" "clouddeploy" {
  project      = var.project_cicd
  account_id   = var.service_account_clouddeploy_name
  display_name = var.service_account_clouddeploy_name
}

# set IAM permissions in project
resource "google_project_iam_binding" "source_admin" {
  project = var.project_cicd
  role    = "roles/source.admin"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "source_reader" {
  project = var.project_cicd
  role    = "roles/source.reader"

  members = [
    "serviceAccount:${google_service_account.cloudbuild.email}",
  ]
}
resource "google_project_iam_binding" "cloudbuild_builds_editor" {
  project = var.project_cicd
  role    = "roles/cloudbuild.builds.editor"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_cicd
  role    = "roles/storage.admin"

  members = [
    "user:${var.iam_member}",
    "serviceAccount:${google_service_account.cloudbuild.email}",
    "serviceAccount:${google_service_account.clouddeploy.email}",
  ]
}
resource "google_project_iam_binding" "serviceusage_serviceUsageConsumer" {
  project = var.project_cicd
  role    = "roles/serviceusage.serviceUsageConsumer"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "artifactregistry_admin" {
  project = var.project_cicd
  role    = "roles/artifactregistry.admin"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "artifactregistry_writer" {
  project = var.project_cicd
  role    = "roles/artifactregistry.writer"

  members = [
    "serviceAccount:${google_service_account.cloudbuild.email}",
  ]
}
resource "google_project_iam_binding" "compute_networkAdmin" {
  project = var.project_cicd
  role    = "roles/compute.networkAdmin"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "cloudbuild_workerPoolOwner" {
  project = var.project_cicd
  role    = "roles/cloudbuild.workerPoolOwner"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "clouddeploy_admin" {
  project = var.project_cicd
  role    = "roles/clouddeploy.admin"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "clouddeploy_releaser" {
  project = var.project_cicd
  role    = "roles/clouddeploy.releaser"

  members = [
    "serviceAccount:${google_service_account.cloudbuild.email}",
  ]
}
resource "google_project_iam_binding" "logging_logWriter" {
  project = var.project_cicd
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.cloudbuild.email}",
    "serviceAccount:${google_service_account.clouddeploy.email}",
  ]
}
resource "google_project_iam_binding" "gkehub_admin" {
  project = var.project_cicd
  role    = "roles/gkehub.admin"

  members = [
    "user:${var.iam_member}",
    "serviceAccount:${google_service_account.clouddeploy.email}",
  ]
}
resource "google_project_iam_binding" "container_admin" {
  project = var.project_gke
  role    = "roles/container.admin"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "gkehub_gatewayAdmin" {
  project = var.project_cicd
  role    = "roles/gkehub.gatewayAdmin"

  members = [
    "serviceAccount:${google_service_account.clouddeploy.email}",
    "user:${var.iam_member}",
  ]
}
resource "google_project_iam_binding" "artifactregistry_reader" {
  project = var.project_cicd
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${var.service_account_gke_email}",
  ]
}

# set IAM perms for SA usage
resource "google_service_account_iam_binding" "cloudbuild_iam_serviceAccountUser" {
  service_account_id = google_service_account.cloudbuild.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "user:${var.iam_member}",
  ]
}
resource "google_service_account_iam_binding" "clouddeploy" {
  service_account_id = google_service_account.clouddeploy.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.cloudbuild.email}",
    "user:${var.iam_member}",
  ]
}

# create SA for gkehub.googleapis.com and grant perms on both projects
resource "google_project_service_identity" "gkehub" {
  provider = google-beta

  project = var.project_cicd
  service = "gkehub.googleapis.com"
}
resource "google_project_iam_member" "gkehub_cicd" {
  project = var.project_cicd
  role    = "roles/gkehub.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.gkehub.email}"
}
resource "google_project_iam_member" "gkehub_gke" {
  project = var.project_gke
  role    = "roles/gkehub.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.gkehub.email}"
}
