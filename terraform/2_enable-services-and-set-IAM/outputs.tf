output "service_account_cloudbuild_email" {
    value = google_service_account.cloudbuild.email
}

output "service_account_clouddeploy_email" {
    value = google_service_account.clouddeploy.email
}
