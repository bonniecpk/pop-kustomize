variable "region" {
  type = string
}

variable "project_cicd" {
  type = string
}

variable "project_gke" {
  type = string
}

variable "gcs_log_bucket_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "service_account_cloudbuild_email" {
  type = string
}

variable "service_account_clouddeploy_email" {
  type = string
}

variable "service_account_gke_email" {
  type = string
}

variable "gke_test_name" {
  type = string
}

variable "gke_stage_name" {
  type = string
}

variable "gke_prod_name" {
  type = string
}

variable "repo" {
  type = string
}