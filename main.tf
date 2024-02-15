terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.region
}

resource "google_compute_network" "vpc-network" {
  name                            = var.vpc_name
  auto_create_subnetworks         = var.autocreatesubnets
  routing_mode                    = var.routingmode
  delete_default_routes_on_create = var.deletedefaultroutes
}

resource "google_compute_subnetwork" "webapp" {
  name                     = var.websubnet_name
  ip_cidr_range            = var.webapp_subnet_cidr
  network                  = google_compute_network.vpc-network.self_link
  private_ip_google_access = var.privateipgoogleaccess
}

resource "google_compute_subnetwork" "db" {
  name                     = var.dbsubnet_name
  ip_cidr_range            = var.db_subnet_cidr
  network                  = google_compute_network.vpc-network.self_link
  private_ip_google_access = var.privateipgoogleaccess
}

resource "google_compute_route" "webapp_route" {
  name             = var.websubnetroutename
  network          = google_compute_network.vpc-network.name
  dest_range       = var.webapp_subnetroute_cidr
  priority         = 1000
  next_hop_gateway = var.nexthopgateway
}

