terraform {
  backend "gcs" {}
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

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
# 1. Bare Container-Optimized OS VM
# ------------------------------------------------------------------------------
resource "google_compute_instance" "otel_gateway" {
  name         = "${var.environment}-otel-gateway"
  machine_type = "e2-standard-2"
  zone         = "${var.region}-a"

  # Single large SSD boot disk running Docker natively
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = data.google_compute_network.vpc.id
    subnetwork = data.google_compute_subnetwork.private.id
  }
  
  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["allow-internal"]
}

# ------------------------------------------------------------------------------
# 2. Private DNS Record for Grafana
# ------------------------------------------------------------------------------
resource "google_dns_record_set" "grafana_record" {
  name         = "grafana.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.otel_gateway.network_interface.0.network_ip]
}
