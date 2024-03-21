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
# Creating a firewall rule to deny inbound SSH traffic
resource "google_compute_firewall" "deny_ssh_inbound" {
  count   = length(var.gcp_vpc)
  name    = "${var.gcp_vpc[count.index].firewall_name}-ssh-inbound"
  network = google_compute_network.VPC[count.index].id
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  source_ranges = var.gcp_vpc[count.index].firewall_source_range
}
# Creating a service account
resource "google_service_account" "service_account" {
  count = length(var.gcp_vpc)
  account_id   = var.gcp_vpc[count.index].service_account
  display_name = var.gcp_vpc[count.index].service_account_display_name
  project =  var.gcp_project
}
resource "google_project_iam_binding" "logging_admin" {
  count  = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
resource "google_project_iam_binding" "monitoring_metric_writer" {
  count  = length(var.gcp_vpc)
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.service_account[count.index].email}"
  ]
}
# Creating a Compute Engine instance with the VPC network
resource "google_compute_instance" "webapp" {
  count        = length(var.gcp_vpc)
  name         = var.gcp_vpc[count.index].vm_name
  machine_type = var.gcp_vpc[count.index].machine_type
  zone         = var.gcp_vpc[count.index].zone
  boot_disk {
    initialize_params {
      image = var.gcp_vpc[count.index].image
      size  = var.gcp_vpc[count.index].disk_size
      type  = var.gcp_vpc[count.index].disk_type
    }
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
    db_port     = 5432
  }
  tags = ["webapp-firewall"]
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
  count    = length(var.gcp_vpc)
  name     = var.gcp_vpc[count.index].dns_name
  type     = "A"
  ttl      = 300
  managed_zone = var.gcp_vpc[count.index].dns_zone_name
  rrdatas = [google_compute_instance.webapp[count.index].network_interface[0].access_config[0].nat_ip]
}