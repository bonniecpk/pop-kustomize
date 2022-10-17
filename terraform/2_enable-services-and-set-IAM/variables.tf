variable "region" {
  type = string
}

variable "project_cicd" {
  type = string
}

variable "project_gke" {
  type = string
}

variable "service_account_cloudbuild_name" {
  type = string
}

variable "service_account_clouddeploy_name" {
  type = string
}

variable "service_account_gke_email" {
  type = string
}

variable "iam_member" {
  type = string
}
