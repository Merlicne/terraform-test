output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "cloud_router_name" {
  description = "The name of the cloud router"
  value       = google_compute_router.router.name
}

output "cloud_nat_name" {
  description = "The name of the cloud NAT"
  value       = google_compute_router_nat.nat.name
}
