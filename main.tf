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
  zone    = var.zone
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

resource "google_compute_firewall" "allowtraffic_applicationport" {
  count   = length(var.vpcs)
  name    = var.allow_traffic
  network = google_compute_network.vpc_network[count.index].name

  allow {
    protocol = var.protocol
    ports    = [var.app_port]
  }

  source_ranges = [var.source_range]
}

resource "google_compute_firewall" "denytraffic_sshport" {
  count   = length(var.vpcs)
  name    = var.deny_traffic
  network = google_compute_network.vpc_network[count.index].name

  deny {
    protocol = var.protocol
    ports    = [var.ssh_port]
  }

  source_ranges = [var.source_range]
}


resource "google_compute_instance" "vm_instance" {
  count = length(var.vpcs)

  name         = var.vm_name
  zone         = var.zone
  machine_type = var.vm_machine_type

  boot_disk {
    initialize_params {
      image = var.vm_image
      type  = var.vm_disk_type
      size  = var.vm_disk_size_gb
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network[count.index].name
    subnetwork = google_compute_subnetwork.webapp[count.index].name

    access_config {

    }
  }
  tags = var.vm_tag

  metadata_startup_script = <<EOT
  touch /tmp/application.properties
echo "spring.datasource.driver-class-name=com.mysql.jdbc.Driver" >> /tmp/application.properties
echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.instance.private_ip_address}/${var.DB_NAME}?createDatabaseIfNotExist=true&useUnicode=true&characterEncoding=utf8" >> /tmp/application.properties
echo "spring.datasource.username=${var.DB_USER}" >> /tmp/application.properties
echo "spring.datasource.password=${random_password.password.result}" >> /tmp/application.properties
echo "spring.jpa.properties.hibernate.show_sql=true" >> /tmp/application.properties
echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect" >> /tmp/application.properties
echo "spring.jpa.hibernate.ddl-auto=update" >> /tmp/application.properties
echo "projectId=${var.project_id}" >> /tmp/application.properties
echo "topicId=${google_pubsub_topic.pub_sub_topic.name}" >> /tmp/application.properties
EOT

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_global_address" "private_ip_address" {
  count         = length(var.vpcs)
  name          = var.private_ipname
  purpose       = var.privateip_purpose
  address_type  = var.privateip_addresstype
  prefix_length = var.privateip_prefixlength
  network       = google_compute_network.vpc_network[count.index].id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = length(var.vpcs)
  network                 = google_compute_network.vpc_network[count.index].id
  service                 = var.vpc_service
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "random_id" "db_name_suffix" {
  byte_length = var.DB_Name_bytelength
}

resource "google_sql_database_instance" "instance" {
  name                = "${var.privateinstance_name}-${random_id.db_name_suffix.hex}"
  region              = var.region
  database_version    = var.DB_version
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.private_vpc_connection]
  settings {
    tier              = var.sql_tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.vpc_network[0].id
    }
    backup_configuration {
      enabled            = var.backup_enabled
      binary_log_enabled = var.backup_binary_log_enabled
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.DB_NAME
  instance = google_sql_database_instance.instance.name
}

resource "random_password" "password" {
  length           = var.password_length
  special          = var.password_special
  override_special = var.password_override
}

resource "google_sql_user" "users" {
  name     = var.DB_USER
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}

resource "google_compute_firewall" "allow_sql_access" {
  name    = var.sql_access
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = var.protocol
    ports    = [var.sql_port]
  }

  source_tags = var.vm_tag
}

resource "google_compute_firewall" "allow_web_access_to_sql" {
  name    = var.web_access
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = var.protocol
    ports    = [var.sql_port]
  }

  source_tags = var.vm_tag
}

output "private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}

data "google_dns_managed_zone" "my_dns_zone" {
  name = var.dnsname
}

# Define the DNS record for your VM instance
resource "google_dns_record_set" "my_dns_record" {
  name         = data.google_dns_managed_zone.my_dns_zone.dns_name
  type         = var.dnsrecord
  ttl          = var.dnsttl
  managed_zone = data.google_dns_managed_zone.my_dns_zone.name
  rrdatas      = [google_compute_instance.vm_instance[0].network_interface[0].access_config[0].nat_ip]
}

resource "google_service_account" "service_account" {
  account_id   = var.serviceaccountid
  display_name = var.serviceaccountname
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_pubsub_topic" "pub_sub_topic" {
  name                       = var.pubsubtopic_name
  message_retention_duration = var.pubsubtopic_message_retention_duration
  depends_on                 = [google_service_networking_connection.private_vpc_connection]
}

resource "google_pubsub_subscription" "pub_sub_subscription" {
  name                 = var.pubsub_subscription_name
  topic                = google_pubsub_topic.pub_sub_topic.name
  ack_deadline_seconds = var.ack_deadline_seconds
  expiration_policy {
    ttl = var.ttl
  }
}

resource "google_service_account" "function_service_account" {
  account_id   = var.cloudfunction_account_id
  display_name = var.cloudfunction_display_name
}

resource "google_project_iam_binding" "function_service_account_roles" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.function_service_account.email}"
  ]
}

resource "google_storage_bucket" "function_code_bucket" {
  name     = var.cloudstorage_bucketname
  location = var.region
}

resource "google_storage_bucket_object" "function_code_objects" {
  name   = var.cloudstorage_bucketobjectname
  bucket = google_storage_bucket.function_code_bucket.name
  source = var.cloudstorage_source
}

resource "google_cloudfunctions2_function" "email_verification_function" {
  name     = var.cloudfunction_name
  location = var.region

  build_config {
    runtime     = var.cloudfunction_runtime
    entry_point = var.cloudfunction_entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.function_code_bucket.name
        object = google_storage_bucket_object.function_code_objects.name
      }
    }
  }

  service_config {
    max_instance_count            = var.max_instance_count
    min_instance_count            = var.min_instance_count
    available_memory              = var.available_memory
    timeout_seconds               = var.timeout_seconds
    vpc_connector                 = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = var.vpc_connector_egress_settings

    environment_variables = {
      SQL_HOST           = google_sql_database_instance.instance.private_ip_address
      SQL_USERNAME       = var.DB_USER
      SQL_PASSWORD       = random_password.password.result
      webappSQL_DATABASE = var.DB_NAME
      MAILGUN_apiKey     = var.MAILGUN_apiKey
      MAILGUN_domain     = var.MAILGUN_domain
    }

    ingress_settings               = var.cloudfunction_ingress_settings
    all_traffic_on_latest_revision = var.cloudfunction_all_traffic_on_latest_revision
    service_account_email          = google_service_account.function_service_account.email


  }
  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.pub_sub_topic.id
    retry_policy   = var.eventtrigger_retry_policy
  }
}

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "pubsub_service_account_roles" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_vpc_access_connector" "connector" {
  name          = var.vpcconnector_name
  region        = var.region
  ip_cidr_range = var.vpcconnector_ip_cidr_range
  network       = google_compute_network.vpc_network[0].name
}
