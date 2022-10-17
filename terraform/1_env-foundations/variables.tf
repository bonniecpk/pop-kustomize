variable "org_id" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "region" {
  type = string
}

variable "workspace_customer_id" {
  type = string
}

variable "folder_prefix" {
  type = string
}

variable "project_prefix" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_region" {
  type = string
}

variable "subnet_ip_cidr_range" {
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

variable "service_account_gke_name" {
  type = string
}
