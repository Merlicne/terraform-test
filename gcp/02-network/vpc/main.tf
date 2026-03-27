terraform {
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------------------
# Enable Required Services
# ------------------------------------------------------------------------------
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dns" {
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# VPC Network
# ------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  
  # Ensure the API is enabled before creating networking resources
  depends_on = [google_project_service.compute]
}

# Public Subnet
resource "google_compute_subnetwork" "public" {
  name                     = "${var.environment}-public-subnet"
  ip_cidr_range            = var.public_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Private Subnet
resource "google_compute_subnetwork" "private" {
  name                     = "${var.environment}-private-subnet"
  ip_cidr_range            = var.private_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Cloud Router (Needed for Cloud NAT)
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT (Allows private subnet to reach internet)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  
  # Only allow the private subnet to use the NAT
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Firewall rule: Allow SSH to all VMs via IAP (Identity-Aware Proxy)
# This is a Google Cloud best practice
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.environment}-allow-iap-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP IP range
  source_ranges = ["35.235.240.0/20"]
}

# Firewall rule: Allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    var.public_subnet_cidr,
    var.private_subnet_cidr,
  ]
}

# ------------------------------------------------------------------------------
# Cloud DNS - Private Zone
# ------------------------------------------------------------------------------
resource "google_dns_managed_zone" "private_zone" {
  name        = "${var.environment}-private-zone"
  dns_name    = var.private_domain_name
  description = "Private DNS zone for internal custom domain"
  
  # Crucial: Make this a PRIVATE zone attached to our VPC
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }

  depends_on = [google_project_service.dns]
}

# ------------------------------------------------------------------------------
# Inbound DNS Forwarding Policy (For Tailscale VPN)
# ------------------------------------------------------------------------------
resource "google_dns_policy" "inbound_dns" {
  name                      = "${var.environment}-inbound-dns"
  enable_inbound_forwarding = true
  description               = "Allows Tailscale to query private Cloud DNS zones"

  networks {
    network_url = google_compute_network.vpc.id
  }

  depends_on = [google_project_service.dns]
}
