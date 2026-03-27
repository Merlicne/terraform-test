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

# ------------------------------------------------------------------------------
# 1. Data Sources (Cross-Tier References)
# ------------------------------------------------------------------------------
# Fetch the Private DNS Zone created in 02-network
data "google_dns_managed_zone" "private_zone" {
  name = "${var.environment}-private-zone"
}

# Dynamically fetch the Observability VM created mathematically in 03-compute
data "google_compute_instance" "otel_gateway" {
  name = "${var.environment}-otel-gateway"
  zone = "${var.region}-a"
}

# ------------------------------------------------------------------------------
# 2. Internal Subdomain Routing
# ------------------------------------------------------------------------------
locals {
  # The IP address dynamically resolved from the Compute Tier
  gateway_ip = data.google_compute_instance.otel_gateway.network_interface.0.network_ip
}

resource "google_dns_record_set" "grafana" {
  name         = "grafana.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.gateway_ip]
}

resource "google_dns_record_set" "prometheus" {
  name         = "prometheus.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.gateway_ip]
}

resource "google_dns_record_set" "loki" {
  name         = "loki.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.gateway_ip]
}

resource "google_dns_record_set" "tempo" {
  name         = "tempo.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.gateway_ip]
}

resource "google_dns_record_set" "otel_collector" {
  name         = "otel-collector.${data.google_dns_managed_zone.private_zone.dns_name}"
  managed_zone = data.google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.gateway_ip]
}