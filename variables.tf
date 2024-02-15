variable "project_id" {
  description = "id for the project"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "websubnet_name" {
  description = "The name of the web subnet"
  type        = string
}

variable "dbsubnet_name" {
  description = "The name of the db subne"
  type        = string
}

variable "websubnetroutename" {
  description = "Route name of the webapp subnet"
  type        = string
}

variable "webapp_subnet_cidr" {
  description = "CIDR for the webapp subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR for the db subnet"
  type        = string
}

variable "webapp_subnetroute_cidr" {
  description = "CIDR for the webapp subnet route"
  type        = string
}

variable "autocreatesubnets" {
  description = "To set value to true or false for automatically creating subnets"
  type        = bool
}

variable "deletedefaultroutes" {
  description = "To set value to true or false to delete default routes"
  type        = bool
}

variable "routingmode" {
  description = "To set routing mode"
  type        = string
}

variable "privateipgoogleaccess" {
  description = "To set private ip google access of subnets to on or off"
  type        = bool
}

variable "nexthopgateway" {
  description = "To set next hop gateway value"
  type        = string
}
