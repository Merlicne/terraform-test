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
# Data Sources for Core Network
# ------------------------------------------------------------------------------
data "google_compute_network" "vpc" {
  name = "${var.environment}-vpc"
}

data "google_compute_subnetwork" "private" {
  name   = "${var.environment}-private-subnet"
  region = var.region
}

data "google_dns_managed_zone" "private_zone" {
  name = "${var.environment}-private-zone"
}

# ------------------------------------------------------------------------------
# Lightweight Nginx Web Server
# ------------------------------------------------------------------------------
resource "google_compute_instance" "test_web_server" {
  name         = "${var.environment}-test-web-server"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.id
    subnetwork = data.google_compute_subnetwork.private.id
    # Note: NO access_config block here! That means NO public IP.
  }

  # Startup script to install Nginx and serve a simple message
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    
    # Write a custom homepage
    sudo tee /var/www/html/index.html > /dev/null <<EOF
    <html>
      <head><title>Success!</title></head>
      <body style="font-family: Arial, sans-serif; text-align: center; margin-top: 50px;">
        <h1>🎉 Hello from the Private Subnet! 🎉</h1>
        <p>If you are reading this on your laptop, your Tailscale VPN is perfectly connected to your Google Cloud environment.</p>
        <p>This VM has <b>NO PUBLIC IP</b> and is completely invisible to the internet.</p>
      </body>
    </html>
    EOF
    
    sudo systemctl restart nginx
  EOT

  tags = ["web-server"]
}

# ------------------------------------------------------------------------------
# Map the Private Domain to the VM's Internal IP
# ------------------------------------------------------------------------------
resource "google_dns_record_set" "test_domain" {
  name         = "hello.${data.google_dns_managed_zone.private_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.private_zone.name
  
  # Point the DNS strictly to the VM's INTERNAL IP
  rrdatas = [google_compute_instance.test_web_server.network_interface[0].network_ip]
}
