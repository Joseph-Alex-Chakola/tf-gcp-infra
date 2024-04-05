resource "google_compute_network" "VPC" {
  count                           = length(var.gcp_vpc)
  name                            = var.gcp_vpc[count.index].name
  routing_mode                    = var.gcp_vpc[count.index].routing_mode
  delete_default_routes_on_create = true
  auto_create_subnetworks         = false
}
# Create a subnet
resource "google_compute_subnetwork" "subnet" {
  count         = length(var.gcp_vpc)
  name          = var.gcp_vpc[count.index].subnet_name_1
  ip_cidr_range = var.gcp_vpc[count.index].subnet_1_cidr
  network       = google_compute_network.VPC[count.index].id
  region        = var.gcp_region
}
# Create a subnet
resource "google_compute_subnetwork" "subnet2" {
  count         = length(var.gcp_vpc)
  name          = var.gcp_vpc[count.index].subnet_name_2
  ip_cidr_range = var.gcp_vpc[count.index].subnet_2_cidr
  network       = google_compute_network.VPC[count.index].id
  region        = var.gcp_region
}

# Creating a route for VPC
resource "google_compute_route" "webapp-route" {
  count            = length(var.gcp_vpc)
  name             = var.gcp_vpc[count.index].subnet_1_custom_route
  network          = google_compute_network.VPC[count.index].id
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
}
# Creating a firewall rule to allow inbound HTTP traffic
resource "google_compute_firewall" "allow_http_inbound" {
  count   = length(var.gcp_vpc)
  name    = "${var.gcp_vpc[count.index].firewall_name}-inbound"
  network = google_compute_network.VPC[count.index].id
  allow {
    protocol = "tcp"
    ports    = var.gcp_vpc[count.index].firewall_port
  }
  direction     = "INGRESS"
  source_ranges = var.gcp_vpc[count.index].firewall_source_range
  target_tags   = ["webapp-firewall"]
}
# resource "google_compute_firewall" "allow_http_lb" {
#   count   = length(var.gcp_vpc)
#   name    = "${var.gcp_vpc[count.index].firewall_name}-lb"
#   network = google_compute_network.VPC[count.index].id
#   priority = 500

#   allow {
#     protocol = "tcp"
#     ports    = var.gcp_vpc[count.index].firewall_port
#   }
#   direction = "INGRESS"
#   source_ranges = ["35.191.0.0/16","130.211.0.0/22"]
#   target_tags = ["webapp-firewall"]
# }
# Creating a firewall rule to deny inbound SSH traffic
resource "google_compute_firewall" "deny_ssh_inbound" {
  count   = length(var.gcp_vpc)
  name    = "${var.gcp_vpc[count.index].firewall_name}-ssh-inbound"
  network = google_compute_network.VPC[count.index].id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  source_ranges = var.gcp_vpc[count.index].firewall_source_range
}
# Creating a service account
resource "google_service_account" "service_account" {
  count        = length(var.gcp_vpc)
  account_id   = var.gcp_vpc[count.index].service_account
  display_name = var.gcp_vpc[count.index].service_account_display_name
  project      = var.gcp_project
}
resource "google_project_iam_binding" "logging_admin" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "monitoring_metric_writer" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "pubsub_publisher" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "vpcaccess" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/vpcaccess.user"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "cloudfunctions" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/cloudfunctions.admin"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "cloudsql" {
  count   = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/cloudsql.editor"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
# # Creating a Compute Engine instance with the VPC network
# resource "google_compute_instance" "webapp" {
#   count        = length(var.gcp_vpc)
#   name         = var.gcp_vpc[count.index].vm_name
#   machine_type = var.gcp_vpc[count.index].machine_type
#   zone         = var.gcp_vpc[count.index].zone
#   boot_disk {
#     initialize_params {
#       image = var.gcp_vpc[count.index].image
#       size  = var.gcp_vpc[count.index].disk_size
#       type  = var.gcp_vpc[count.index].disk_type
#     }
#   }
#   network_interface {
#     network    = google_compute_network.VPC[count.index].name
#     subnetwork = google_compute_subnetwork.subnet[count.index].id
#     access_config {
#     }
#   }
#   service_account {
#     email  = google_service_account.service_account[count.index].email
#     scopes = ["cloud-platform"]
#   }
#   metadata = {
#     db_password = random_password.password.result,
#     db_username = var.gcp_vpc[count.index].db_username,
#     db_name     = var.gcp_vpc[count.index].db_name,
#     db_host     = google_sql_database_instance.db_instance[count.index].ip_address[0].ip_address,
#     db_port     = 5432,
#     project_id  = var.gcp_project,
#     topic_id    = google_pubsub_topic.email.name
#   }
#   tags = ["webapp-firewall"]
# }

# Creating a Compute Engine instance template
resource "google_compute_instance_template" "webapp_template" {
  count        = length(var.gcp_vpc)
  name_prefix  = var.gcp_vpc[count.index].vm_name
  machine_type = var.gcp_vpc[count.index].machine_type
  disk {
    source_image = var.gcp_vpc[count.index].image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.gcp_vpc[count.index].disk_size
    disk_type    = var.gcp_vpc[count.index].disk_type
  }
  network_interface {
    network    = google_compute_network.VPC[count.index].name
    subnetwork = google_compute_subnetwork.subnet[count.index].id
    access_config {
    }
  }
  service_account {
    email  = google_service_account.service_account[count.index].email
    scopes = ["cloud-platform"]
  }
  metadata = {
    db_password = random_password.password.result,
    db_username = var.gcp_vpc[count.index].db_username,
    db_name     = var.gcp_vpc[count.index].db_name,
    db_host     = google_sql_database_instance.db_instance[count.index].ip_address[0].ip_address,
    db_port     = 5432,
    project_id  = var.gcp_project,
    topic_id    = google_pubsub_topic.email.name
  }
  tags = ["webapp-firewall"]
  lifecycle {
    create_before_destroy = true
  }
}
# Compute Health Check
resource "google_compute_health_check" "my_health_check" {
  name                = "webapp-health-check"
  check_interval_sec  = 60
  healthy_threshold   = 1
  unhealthy_threshold = 2
  timeout_sec         = 20
  http_health_check {
    port         = "8080"
    request_path = "/healthz"
  }
}
# Compute instance group
resource "google_compute_region_instance_group_manager" "webapp_igm" {
  count                     = length(var.gcp_vpc)
  name                      = "${var.gcp_vpc[count.index].vm_name}-igm"
  base_instance_name        = var.gcp_vpc[count.index].vm_name
  region                    = var.gcp_region
  distribution_policy_zones = var.gcp_vpc[count.index].distribution_policy_zones
  version {
    name              = "version-1"
    instance_template = google_compute_instance_template.webapp_template[count.index].self_link
  }
  named_port {
    name = "http-connect"
    port = 8080
  }
  auto_healing_policies {
    initial_delay_sec = "300"
    health_check      = google_compute_health_check.my_health_check.id
  }
}
# Create an regional autoscaler
resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  count      = length(var.gcp_vpc)
  name       = var.gcp_vpc[count.index].autoscaler_name
  region     = var.gcp_region
  target     = google_compute_region_instance_group_manager.webapp_igm[count.index].id
  depends_on = [google_compute_region_autoscaler.webapp_autoscaler]
  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 90
    cpu_utilization {
      target = 0.05
    }
  }
}
resource "google_compute_global_address" "private_ip_range" {
  count         = length(var.gcp_vpc)
  name          = var.gcp_vpc[count.index].global_address_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.VPC[count.index].id
}
# Creating a private connection to the Google Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = length(var.gcp_vpc)
  network                 = google_compute_network.VPC[count.index].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range[count.index].name]
  deletion_policy         = "ABANDON"
}
# Creating a google_cloud_sql_instance
resource "google_sql_database_instance" "db_instance" {
  count               = length(var.gcp_vpc)
  name                = var.gcp_vpc[count.index].db_instance_name
  database_version    = var.gcp_vpc[count.index].db_version
  region              = var.gcp_region
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
  settings {
    tier = var.gcp_vpc[count.index].db_tier
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.VPC[count.index].id
      enable_private_path_for_google_cloud_services = true
    }
    disk_autoresize   = true
    disk_type         = var.gcp_vpc[count.index].db_disk_type
    disk_size         = var.gcp_vpc[count.index].db_disk_size
    availability_type = var.gcp_vpc[count.index].availability_type
  }
  lifecycle {
    prevent_destroy = false
  }
}
# Creating a database
resource "google_sql_database" "database" {
  count    = length(var.gcp_vpc)
  name     = var.gcp_vpc[count.index].db_name
  instance = google_sql_database_instance.db_instance[count.index].name
}
# Random password generation
resource "random_password" "password" {
  length  = 16
  special = true
}
# Creating a user
resource "google_sql_user" "new_user" {
  count           = length(var.gcp_vpc)
  name            = var.gcp_vpc[count.index].db_username
  instance        = google_sql_database_instance.db_instance[count.index].name
  password        = random_password.password.result
  depends_on      = [google_sql_database_instance.db_instance]
  deletion_policy = "ABANDON"
}
resource "google_dns_record_set" "new_record" {
  count        = length(var.gcp_vpc)
  name         = var.gcp_vpc[count.index].dns_name
  type         = "A"
  ttl          = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas      = [module.gce-lb-http[count.index].external_ip]
}
resource "google_dns_record_set" "spf_record" {
  count        = length(var.gcp_vpc)
  name         = var.gcp_vpc[count.index].dns_name
  type         = "TXT"
  ttl          = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas      = ["v=spf1 include:mailgun.org ~all"]
}
resource "google_dns_record_set" "dkim_record" {
  count        = length(var.gcp_vpc)
  name         = "smtp._domainkey.${var.gcp_vpc[count.index].dns_name}"
  type         = "TXT"
  ttl          = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas      = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrS0f4Ud8CVUOFc4b4wlZgpxMrgJOOmroNkDwfAdSbwAy6c5bR2zw5mPNmDBl7b+T8O3Q49ZN1r6DlyifW5gOsFUlWphhLUCcwIbAC7Nx7Ul8YKp/WbfbDXpsulGvhOOifGMe5tcbOoKDQeobuJMdyvS8BLtuCtXDqiEoykRHHRQIDAQAB"]
}
resource "google_dns_record_set" "mx_record" {
  count        = length(var.gcp_vpc)
  name         = var.gcp_vpc[count.index].dns_name
  type         = "MX"
  ttl          = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas      = ["10 mxa.mailgun.org.", "20 mxb.mailgun.org."]
}
resource "google_dns_record_set" "cname_record" {
  count        = length(var.gcp_vpc)
  name         = "email.${var.gcp_vpc[count.index].dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas      = ["mailgun.org."]
}
resource "google_pubsub_topic" "email" {
  name = "verify_email"
  labels = {
    purpose = "email_verification"
  }
  message_retention_duration = "604800s"
}
resource "google_storage_bucket" "bucket" {
  count         = length(var.gcp_vpc)
  name          = var.gcp_vpc[count.index].serverless_bucket_name
  location      = "US"
  force_destroy = true

}
resource "google_storage_bucket_object" "object" {
  count  = length(var.gcp_vpc)
  name   = "my-object.jar"
  bucket = google_storage_bucket.bucket[count.index].name
  source = var.gcp_vpc[count.index].serverless_bucket_source
}
resource "google_vpc_access_connector" "connector" {
  count          = length(var.gcp_vpc)
  name           = "connector-${count.index}"
  network        = google_compute_network.VPC[count.index].id
  machine_type   = "f1-micro"
  region         = var.gcp_region
  max_throughput = 1000
  min_throughput = 200
  min_instances  = 2
  max_instances  = 3
  ip_cidr_range  = var.gcp_vpc[count.index].connector_ip_cidr_range
}

resource "google_cloudfunctions2_function" "serverless_mail" {
  count       = length(var.gcp_vpc)
  name        = var.gcp_vpc[count.index].serverless_function_name
  location    = var.gcp_region
  description = var.gcp_vpc[count.index].serverless_function_description
  build_config {
    runtime     = var.gcp_vpc[count.index].serverless_function_runtime
    entry_point = var.gcp_vpc[count.index].serverless_function_entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.bucket[count.index].name
        object = google_storage_bucket_object.object[count.index].name
      }
    }
  }
  service_config {
    available_memory               = "256M"
    timeout_seconds                = 60
    max_instance_count             = 3
    min_instance_count             = 2
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = var.gcp_vpc[count.index].cloud_function_service_account
    environment_variables = {
      "DB_PASSWORD"     = random_password.password.result,
      "DB_USERNAME"     = var.gcp_vpc[count.index].db_username,
      "DB_NAME"         = var.gcp_vpc[count.index].db_name,
      "DB_HOST"         = google_sql_database_instance.db_instance[count.index].ip_address[0].ip_address,
      "DB_PORT"         = 5432,
      "DOMAIN"          = "josephalex.me",
      "MAILGUN_API_KEY" = var.gcp_vpc[count.index].api_key
    }
    vpc_connector                 = google_vpc_access_connector.connector[count.index].id
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  }

  event_trigger {
    trigger_region        = var.gcp_region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.email.id
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = var.gcp_vpc[count.index].cloud_function_service_account
  }
}
# GCP Provider  for Load Balancer
provider "google-beta" {
  credentials = file(var.gcp_svc_key)
  project     = var.gcp_project
  region      = var.gcp_region
}
module "gce-lb-http" {
  count                           = length(var.gcp_vpc)
  source                          = "terraform-google-modules/lb-http/google"
  version                         = "~> 10.0"
  name                            = "webapp-lb"
  project                         = var.gcp_project
  target_tags                     = ["webapp-firewall"]
  ssl                             = true
  managed_ssl_certificate_domains = [var.gcp_vpc[count.index].domain_name]
  backends = {
    default = {
      protocol    = "HTTP"
      port        = 8080
      port_name   = "http-connect"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        logging            = true
        timeout_sec        = 20
        check_interval_sec = 60
        request_path       = "/healthz"
        port               = 8080
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = google_compute_region_instance_group_manager.webapp_igm[count.index].instance_group
        },
      ]
      iap_config = {
        enable = false
      }
    }
  }
}
