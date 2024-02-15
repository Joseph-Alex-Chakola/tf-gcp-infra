resource "google_compute_network" "VPC" {
    name = var.gcp_vpc_name
    routing_mode = "REGIONAL"
    delete_default_routes_on_create = true
    auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
    name = "${var.subnet_name_1}"
    ip_cidr_range = "10.10.10.0/${var.subnet_1_cidr}"
    network = google_compute_network.VPC.id
    region = var.gcp_region
}
# Create a subnet
resource "google_compute_subnetwork" "subnet2" {
    name = "${var.subnet_name_2}"
    ip_cidr_range = "10.10.1.0/${var.subnet_2_cidr}"
    network = google_compute_network.VPC.id
    region = var.gcp_region
}

# Creating a route for subnet 1
resource "google_compute_route" "webapp-route" {
    name = "${var.subnet_1_custom_route}"
    network = google_compute_network.VPC.id
    dest_range = "0.0.0.0/0"
    next_hop_gateway = "default-internet-gateway"
}



