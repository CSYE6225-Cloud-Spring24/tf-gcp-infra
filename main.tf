provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                            = var.vpcs[0].vpc_name
  auto_create_subnetworks         = var.autocreatesubnets
  routing_mode                    = var.routingmode
  delete_default_routes_on_create = var.deletedefaultroutes
}

resource "google_compute_subnetwork" "webapp" {
  name                     = var.vpcs[0].websubnet_name
  ip_cidr_range            = var.vpcs[0].webapp_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = var.vpcs[0].privateipgoogleaccess
}

resource "google_compute_subnetwork" "db" {
  name                     = var.vpcs[0].dbsubnet_name
  ip_cidr_range            = var.vpcs[0].db_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = var.vpcs[0].privateipgoogleaccess
}

resource "google_compute_route" "webapp_route" {
  name             = var.vpcs[0].websubnetroutename
  network          = google_compute_network.vpc_network.self_link
  dest_range       = var.webapp_subnetroute_cidr
  priority         = 1000
  next_hop_gateway = var.nexthopgateway
}

resource "google_compute_firewall" "allowtraffic_applicationport" {
  name    = var.allow_traffic
  network = google_compute_network.vpc_network.name

  allow {
    protocol = var.protocol
    ports    = [var.app_port]
  }

  # source_ranges = [var.source_range]
  source_ranges = [google_compute_global_address.lb_ipv4_address.address]

  target_tags = var.vm_tag


}

resource "google_compute_firewall" "denytraffic_sshport" {
  name    = var.deny_traffic
  network = google_compute_network.vpc_network.name

  deny {
    protocol = var.protocol
    ports    = [var.ssh_port]
  }

  source_ranges = [var.source_range]
}

resource "google_compute_global_address" "private_ip_address" {
  name          = var.private_ipname
  purpose       = var.privateip_purpose
  address_type  = var.privateip_addresstype
  prefix_length = var.privateip_prefixlength
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = var.vpc_service
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
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
      private_network = google_compute_network.vpc_network.id
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
  network = google_compute_network.vpc_network.name

  allow {
    protocol = var.protocol
    ports    = [var.sql_port]
  }

  source_tags = var.vm_tag
}

resource "google_compute_firewall" "allow_web_access_to_sql" {
  name    = var.web_access
  network = google_compute_network.vpc_network.name

  allow {
    protocol = var.protocol
    ports    = [var.sql_port]
  }

  source_tags = var.vm_tag
}

output "private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}

data "google_dns_managed_zone" "existing_zone" {
  name = var.dnszonename
}

resource "google_dns_record_set" "dns_record" {
  name         = var.dnsname
  type         = var.dnsrecord
  ttl          = var.dnsttl
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.lb_ipv4_address.address]
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
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
  network       = google_compute_network.vpc_network.name
}

resource "google_project_iam_binding" "invoker_binding" {
  members = ["serviceAccount:${google_service_account.function_service_account.email}"]
  project = var.project_id
  role    = "roles/run.invoker"
}

resource "google_compute_region_instance_template" "regional_template" {
  name_prefix  = var.regional_template
  machine_type = var.vm_machine_type
  region       = var.region

  disk {
    source_image = var.vm_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.vm_disk_size_gb
    disk_type    = var.vm_disk_type

  }

  # Define networking
  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.webapp.self_link
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
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.vm_environment
    app         = var.vm_app
  }
}

resource "google_compute_http_health_check" "http_health_check" {
  name                = var.health_check
  check_interval_sec  = var.hc_check_interval_sec
  timeout_sec         = var.hc_timeout_sec
  healthy_threshold   = var.hc_healthy_threshold
  unhealthy_threshold = var.hc_unhealthy_threshold
  port                = var.hc_port
  request_path        = var.hc_request_path
}

resource "google_compute_region_instance_group_manager" "webapp_igm" {
  name               = var.instance_group_manager
  region             = var.region
  base_instance_name = var.igm_base_instance_name

  version {
    instance_template = google_compute_region_instance_template.regional_template.id
    name              = var.igm_version_name
  }


  named_port {
    name = var.igm_namedport_name
    port = var.igm_namedport_port
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.http_health_check.self_link
    initial_delay_sec = var.autohealing_initial_delay_sec
  }

  target_size = var.vm_target_size

}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = var.autoscaler
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_igm.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.target
    }
  }

}

resource "google_compute_global_address" "lb_ipv4_address" {

  name = var.lb_address
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = var.forwardingrule_name
  ip_protocol           = var.forwardingrule_ip_protocol
  load_balancing_scheme = var.forwardingrule_load_balancing_scheme
  ip_address            = google_compute_global_address.lb_ipv4_address.address
  port_range            = var.forwardingrule_port_range
  target                = google_compute_target_https_proxy.https_proxy.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name     = var.https_proxy
  provider = google
  url_map  = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.webapp_ssl_cert.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.webapp_ssl_cert
  ]
}

resource "google_compute_url_map" "default" {
  name            = var.lb_url_map
  provider        = google
  default_service = google_compute_backend_service.webapp_backend.id
}

resource "google_compute_managed_ssl_certificate" "webapp_ssl_cert" {
  name = var.ssl_certificate

  managed {
    domains = [var.dnsname]
  }
}

resource "google_compute_backend_service" "webapp_backend" {
  name                            = var.lb_backend_name
  protocol                        = var.lb_backend_protocol
  port_name                       = var.lb_backend_port_name
  health_checks                   = [google_compute_http_health_check.http_health_check.id]
  load_balancing_scheme           = var.forwardingrule_load_balancing_scheme
  timeout_sec                     = var.backend_timeout_sec
  enable_cdn                      = var.backend_enable_cdn
  connection_draining_timeout_sec = var.backend_connection_draining_timeout_sec
  backend {
    group           = google_compute_region_instance_group_manager.webapp_igm.instance_group
    balancing_mode  = var.lb_backend_balancing_mode
    capacity_scaler = 1.0
  }
}

resource "google_logging_metric" "igm_metric" {
  name        = "igm-logs"
  description = "Logs for instance group manager"

  filter = "resource.type=\"gce_instance_group_manager\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "autoscaler_metric" {
  name        = "autoscaler-logs"
  description = "Logs for autoscaler"

  filter = "resource.type=\"gce_autoscaler\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "backend_metric" {
  name        = "backend-logs"
  description = "Logs for load balancer backends"

  filter = "resource.type=\"http_load_balancer\" AND resource.labels.backend_type=\"instance_group\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_compute_firewall" "allow_lb" {
  name    = var.lb_firewall_name
  network = google_compute_network.vpc_network.id

  allow {
    protocol = var.lb_firewall_protocol
    ports    = var.lb_firewall_ports
  }

  source_ranges = var.lb_firewall_source_ranges
  source_tags   = var.vm_tag
}

resource "google_project_iam_binding" "instance_admin_binding" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"

  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}

resource "google_service_account" "vm_service_account" {
  account_id   = var.Autoscaler_service_account_name
  display_name = var.Autoscaler_service_account_display_name
}

resource "google_compute_firewall" "default" {
  name          = var.hc_firewall_name
  provider      = google
  direction     = var.hc_firewall_direction
  network       = google_compute_network.vpc_network.id
  source_ranges = var.hc_firewall_source_ranges
  allow {
    protocol = var.hc_firewall_protocol
  }
  target_tags = var.hc_firewall_target_tags
}

