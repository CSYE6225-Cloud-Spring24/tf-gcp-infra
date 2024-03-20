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

variable "vpcs" {
  description = "A list of objects representing VPC configurations"
  type = list(object({
    name = string
    # description = "The name of the VPC"
    vpc_name = string
    # description = "The name of web subnet"
    websubnet_name = string
    # description = "The name of db subnet"
    dbsubnet_name = string
    # description = "CIDR for the webapp subnet"
    webapp_subnet_cidr = string
    # description = "CIDR for the db subnet"
    db_subnet_cidr = string
    # description = "CIDR for the webapp subnet route"
    websubnetroutename = string
    # description = "To set private ip google access of subnets to on or off"
    privateipgoogleaccess = bool
  }))
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

variable "nexthopgateway" {
  description = "To set next hop gateway value"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_machine_type" {
  description = "Machine type of the VM"
  type        = string
}

variable "vm_image" {
  description = "Custom image of the VM boot disk"
  type        = string
}

variable "vm_disk_type" {
  description = "Disk type of the VM boot disk"
  type        = string
}

variable "vm_disk_size_gb" {
  description = "Size of the VM boot disk in GB"
  type        = number
}

variable "app_port" {
  description = "The application port to allow through the firewall"
  type        = string
}

variable "deletion_protection" {
  description = "Value for deletion protection"
  type        = bool
}

variable "availability_type" {
  description = "Value for availability type"
  type        = string
}

variable "disk_type" {
  description = "Value for disk type"
  type        = string
}

variable "disk_size" {
  description = "Value for disk size"
  type        = number
}

variable "ipv4_enabled" {
  description = "Value for IPv4 enabled"
  type        = bool
}

variable "vm_tag" {
  description = "Tags to apply to Compute Engine instances"
  type        = list(string)
}

variable "DB_NAME" {
  description = "Name of the database"
  type        = string
}
variable "DB_USER" {
  description = "Name of the database user"
  type        = string
}
variable "sql_access" {
  description = "Name of the sql access firewall"
  type        = string
}
variable "web_access" {
  description = "Name of the web access to sql firewall"
  type        = string
}
variable "password_length" {
  description = "Length of DB password"
  type        = number
}
variable "password_special" {
  description = "Allow special characters in password"
  type        = bool
}
variable "password_override" {
  description = "Override special characters in password"
  type        = string
}

variable "password_sensitive" {
  description = "Hides password"
  type        = bool
}

variable "backup_enabled" {
  description = "To enable backup"
  type        = bool
}
variable "backup_binary_log_enabled" {
  description = "To enable binary log"
  type        = bool
}

variable "protocol" {
  description = "Type of protocol"
  type        = string
}

variable "sql_port" {
  description = "Port number of sql"
  type        = number
}

variable "sql_tier" {
  description = "Tier of the cloudsql instance"
  type        = string
}

variable "DB_version" {
  description = "Database Version"
  type        = string
}

variable "DB_Name_bytelength" {
  description = "Bytelength of DB name"
  type        = number
}

variable "vpc_service" {
  description = "Private connection service"
  type        = string
}

variable "private_ipname" {
  description = "Name of the Private IP Address"
  type        = string
}

variable "privateip_purpose" {
  description = "Purpose of the Private IP Address"
  type        = string
}

variable "privateip_addresstype" {
  description = "Address Type of the Private IP"
  type        = string
}

variable "privateip_prefixlength" {
  description = "Prefix Length of the Private IP"
  type        = number
}

variable "ssh_port" {
  description = "ssh port number"
  type        = string
}

variable "source_range" {
  description = "source range"
  type        = string
}

variable "allow_traffic" {
  description = "Allow traffic on application port"
  type        = string
}

variable "deny_traffic" {
  description = "Deny traffic on ssh port"
  type        = string
}

variable "privateinstance_name" {
  description = "Name of the private instance"
  type        = string
}

variable "dnsname" {
  description = "Name of the Domain"
  type        = string
}

variable "dnsrecord" {
  description = "Name of the DNS Record"
  type        = string
}

variable "dnsttl" {
  description = "Time to live"
  type        = number
}

variable "serviceaccountid" {
  description = "Service Account ID"
  type        = string
}

variable "serviceaccountname" {
  description = "Service Account Name"
  type        = string
}
