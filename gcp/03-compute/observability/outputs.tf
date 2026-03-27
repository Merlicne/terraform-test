output "otel_internal_ip" {
  description = "The internal private IP of the OpenTelemetry Gateway VM"
  value       = google_compute_instance.otel_gateway.network_interface.0.network_ip
}

output "otel_collector_grpc" {
  description = "The endpoint your future applications should send traces/metrics to"
  value       = "${google_compute_instance.otel_gateway.network_interface.0.network_ip}:4317"
}
