output "private_ip" {
  value = google_compute_instance.test_web_server.network_interface[0].network_ip
}

output "private_url" {
  value = "http://${google_dns_record_set.test_domain.name}"
}
