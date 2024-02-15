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
resource "google_compute_network" "vpc_network" {
  count                           = length(var.vpcs)
  name                            = var.vpcs[count.index].vpc_name
  auto_create_subnetworks         = var.autocreatesubnets
  routing_mode                    = var.routingmode
  delete_default_routes_on_create = var.deletedefaultroutes
}

resource "google_compute_subnetwork" "webapp" {
  count                    = length(var.vpcs)
  name                     = var.vpcs[count.index].websubnet_name
  ip_cidr_range            = var.vpcs[count.index].webapp_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = var.vpcs[count.index].privateipgoogleaccess
}
resource "google_compute_subnetwork" "db" {
  count                    = length(var.vpcs)
  name                     = var.vpcs[count.index].dbsubnet_name
  ip_cidr_range            = var.vpcs[count.index].db_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = var.vpcs[count.index].privateipgoogleaccess
}

resource "google_compute_route" "webapp_route" {
  count            = length(var.vpcs)
  name             = var.vpcs[count.index].websubnetroutename
  network          = google_compute_network.vpc_network[count.index].self_link
  dest_range       = var.webapp_subnetroute_cidr
  priority         = 1000
  next_hop_gateway = var.nexthopgateway
}

