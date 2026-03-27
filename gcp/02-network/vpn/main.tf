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

# Fetch the existing VPC (managed by the gcp/network/vpc project)
data "google_compute_network" "vpc" {
  name = "${var.environment}-vpc"
}

# Fetch the existing Private Subnet
data "google_compute_subnetwork" "private" {
  name   = "${var.environment}-private-subnet"
  region = var.region
}

# Fetch the existing Public Subnet
data "google_compute_subnetwork" "public" {
  name   = "${var.environment}-public-subnet"
  region = var.region
}

# Tailscale VPN Subnet Router
resource "google_compute_instance" "vpn_gateway" {
  name         = "${var.environment}-tailscale-router"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.id
    subnetwork = data.google_compute_subnetwork.private.id
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    
    # 1. Enable IP forwarding in Linux kernel
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
    
    # 2. Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    
    # 3. Authenticate to Tailscale and dynamically advertise the routes!
    sudo tailscale up --authkey="${var.tailscale_auth_key}" --advertise-routes="${data.google_compute_subnetwork.public.ip_cidr_range},${data.google_compute_subnetwork.private.ip_cidr_range}"
  EOT

  tags = ["vpn", "tailscale"]
}
