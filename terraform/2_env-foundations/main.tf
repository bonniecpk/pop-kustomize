terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
  }
}

/******************************************
  Setup impersonation
 *****************************************/
provider "google" {
  region = var.region
  alias  = "impersonation"
}

data "google_client_config" "default" {
  provider = google.impersonation
}

data "google_service_account_access_token" "sa" {
  provider               = google.impersonation
  target_service_account = "terraform-sa@kwpark-test-123.iam.gserviceaccount.com"
  lifetime               = "600s"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}

# use this provider when need to intereact with restricted APIs e.g. org policy and VPC-SC
provider "google" {
  access_token = data.google_service_account_access_token.sa.access_token
  alias        = "sa"
}

# default provider that uses user perms
provider "google" {
  region = var.region
}
/******************************************
  End token generation for impersonation
 *****************************************/

# random number to append to resources
resource "random_id" "id" {
  byte_length = 4
}

locals {
  folder       = "${var.folder_prefix}-${random_id.id.hex}"
  project_cicd = "${var.project_prefix}-cicd-${random_id.id.hex}"
  project_gke  = "${var.project_prefix}-gke-${random_id.id.hex}"
}

# create folder
resource "google_folder" "folder" {
  display_name = local.folder
  parent       = "organizations/${var.org_id}"
}

# apply org policies onto folder 
resource "google_org_policy_policy" "compute_vmExternalIpAccess" {
  provider = google.sa

  name   = "${google_folder.folder.name}/policies/compute.vmExternalIpAccess"
  parent = google_folder.folder.name

  spec {
    inherit_from_parent = false

    rules {
      deny_all = "TRUE"
    }
  }

  depends_on = [
    google_folder.folder,
  ]
}
resource "google_org_policy_policy" "iam_allowedPolicyMemberDomains" {
  provider = google.sa

  name   = "${google_folder.folder.name}/policies/constraints/iam.allowedPolicyMemberDomains"
  parent = google_folder.folder.name

  spec {
    inherit_from_parent = false

    rules {
      values {
        allowed_values = [
          var.workspace_customer_id,
        ]
      }
    }
  }

  depends_on = [
    google_folder.folder,
  ]
}
resource "google_org_policy_policy" "compute_skipDefaultNetworkCreation" {
  provider = google.sa

  name   = "${google_folder.folder.name}/policies/constraints/compute.skipDefaultNetworkCreation"
  parent = google_folder.folder.name

  spec {
    inherit_from_parent = false

    rules {
      enforce = "TRUE"
    }
  }

  depends_on = [
    google_folder.folder,
  ]
}

# create project
resource "google_project" "cicd" {
  name            = local.project_cicd
  project_id      = local.project_cicd
  folder_id       = google_folder.folder.name
  billing_account = var.billing_account

  depends_on = [
    google_org_policy_policy.compute_vmExternalIpAccess,
    google_org_policy_policy.iam_allowedPolicyMemberDomains,
    google_org_policy_policy.compute_skipDefaultNetworkCreation,
  ]
}

# create project
resource "google_project" "gke" {
  name            = local.project_gke
  project_id      = local.project_gke
  folder_id       = google_folder.folder.name
  billing_account = var.billing_account

  depends_on = [
    google_org_policy_policy.compute_vmExternalIpAccess,
    google_org_policy_policy.iam_allowedPolicyMemberDomains,
    google_org_policy_policy.compute_skipDefaultNetworkCreation,
  ]
}

# enable required services
resource "google_project_service" "compute_cicd" {
  project = google_project.cicd.id
  service = "compute.googleapis.com"
}
resource "google_project_service" "compute_gke" {
  project = google_project.gke.id
  service = "compute.googleapis.com"
}
resource "google_project_service" "container_gke" {
  project = google_project.gke.id
  service = "container.googleapis.com"
}

# create custom VPC in each project
resource "google_compute_network" "cicd" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = local.project_cicd

  depends_on = [
    google_project_service.compute_cicd,
  ]
}
resource "google_compute_network" "gke" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = local.project_gke

  depends_on = [
    google_project_service.compute_gke,
  ]
}

# create subnet in each VPC
resource "google_compute_subnetwork" "cicd" {
  name                     = var.subnet_region
  project                  = local.project_cicd
  ip_cidr_range            = var.subnet_ip_cidr_range
  region                   = var.subnet_region
  network                  = google_compute_network.cicd.id
  private_ip_google_access = true
}
resource "google_compute_subnetwork" "gke" {
  name                     = var.subnet_region
  project                  = local.project_gke
  ip_cidr_range            = var.subnet_ip_cidr_range
  region                   = var.subnet_region
  network                  = google_compute_network.gke.id
  private_ip_google_access = true
}

# create SA in GKE project for GKE cluster
resource "google_service_account" "gke" {
  project      = local.project_gke
  account_id   = var.service_account_gke_name
  display_name = var.service_account_gke_name

  depends_on = [
    google_project_service.container_gke
  ]
}

# create 3X private GKE clusters in the GKE project
resource "google_container_cluster" "test" {
  project            = local.project_gke
  name               = var.gke_test_name
  location           = var.region
  initial_node_count = 1
  networking_mode    = "VPC_NATIVE"
  network            = google_compute_network.gke.id
  subnetwork         = google_compute_subnetwork.gke.id

  node_config {
    machine_type = "e2-medium"

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  ip_allocation_policy {
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${local.project_gke}.svc.id.goog"
  }
}
resource "google_container_cluster" "stage" {
  project            = local.project_gke
  name               = var.gke_stage_name
  location           = var.region
  initial_node_count = 1
  networking_mode    = "VPC_NATIVE"
  network            = google_compute_network.gke.id
  subnetwork         = google_compute_subnetwork.gke.id

  node_config {
    machine_type = "e2-medium"

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  ip_allocation_policy {
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.16/28"
  }

  workload_identity_config {
    workload_pool = "${local.project_gke}.svc.id.goog"
  }
}
resource "google_container_cluster" "prod" {
  project            = local.project_gke
  name               = var.gke_prod_name
  location           = var.region
  initial_node_count = 1
  networking_mode    = "VPC_NATIVE"
  network            = google_compute_network.gke.id
  subnetwork         = google_compute_subnetwork.gke.id

  node_config {
    machine_type = "e2-medium"

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  ip_allocation_policy {
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.48/28"
  }

  workload_identity_config {
    workload_pool = "${local.project_gke}.svc.id.goog"
  }
}
