resource "google_compute_network" "VPC" {
    count = length(var.gcp_vpc)
    name = var.gcp_vpc[count.index].name
    routing_mode = var.gcp_vpc[count.index].routing_mode
    delete_default_routes_on_create = true
    auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
    count = length(var.gcp_vpc)
    name = var.gcp_vpc[count.index].subnet_name_1
    ip_cidr_range = var.gcp_vpc[count.index].subnet_1_cidr
    network = google_compute_network.VPC[count.index].id
    region = var.gcp_region
}
# Create a subnet
resource "google_compute_subnetwork" "subnet2" {
    count = length(var.gcp_vpc)
    name = var.gcp_vpc[count.index].subnet_name_2
    ip_cidr_range = var.gcp_vpc[count.index].subnet_2_cidr
    network = google_compute_network.VPC[count.index].id
    region = var.gcp_region
}

# Creating a route for VPC
resource "google_compute_route" "webapp-route" {
    count = length(var.gcp_vpc)
    name = var.gcp_vpc[count.index].subnet_1_custom_route
    network = google_compute_network.VPC[count.index].id
    dest_range = "0.0.0.0/0"
    next_hop_gateway = "default-internet-gateway"
}
# Creating a firewall rule to allow inbound HTTP traffic
resource "google_compute_firewall" "allow_http_inbound" {
    count = length(var.gcp_vpc)
    name = "${var.gcp_vpc[count.index].firewall_name}-inbound"
    network = google_compute_network.VPC[count.index].id
    allow {
        protocol = "tcp"
        ports = var.gcp_vpc[count.index].firewall_port
    }
    direction = "INGRESS"
    source_ranges = var.gcp_vpc[count.index].firewall_source_range
    target_tags = ["webapp-firewall"]
}
# Creating a firewall rule to deny inbound SSH traffic
resource "google_compute_firewall" "deny_ssh_inbound" {
    count = length(var.gcp_vpc)
    name = "${var.gcp_vpc[count.index].firewall_name}-ssh-inbound"
    network = google_compute_network.VPC[count.index].id
    deny {
        protocol = "tcp"
        ports = ["22"]
    }
    direction = "INGRESS"
    source_ranges = var.gcp_vpc[count.index].firewall_source_range
}
# Creating a Compute Engine instance with the VPC network
resource "google_compute_instance" "webapp" {
    count = length(var.gcp_vpc)
    name = var.gcp_vpc[count.index].vm_name
    machine_type = var.gcp_vpc[count.index].machine_type
    zone = var.gcp_vpc[count.index].zone
    boot_disk {
        initialize_params {
            image = var.gcp_vpc[count.index].image
            size  = var.gcp_vpc[count.index].disk_size
            type  = var.gcp_vpc[count.index].disk_type
        }
    }
    network_interface {
        network = google_compute_network.VPC[count.index].name
        subnetwork = google_compute_subnetwork.subnet[count.index].id
        access_config {
        }
    }
    tags = ["webapp-firewall"]
}



