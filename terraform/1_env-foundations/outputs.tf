output "project_cicd" {
  value = local.project_cicd
}

output "project_gke" {
  value = local.project_gke
}

output "vpc_cicd" {
  value = google_compute_network.cicd.id
}

output "vpc_gke" {
  value = google_compute_network.gke.id
}

output "serviceAccount_gke" {
  value = google_service_account.gke.email
}

output "gke_test" {
  value = google_container_cluster.test.id
}

output "gke_stage" {
  value = google_container_cluster.stage.id
}

output "gke_prod" {
  value = google_container_cluster.prod.id
}