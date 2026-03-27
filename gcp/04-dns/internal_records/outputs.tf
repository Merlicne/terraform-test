output "grafana_url" {
  description = "Access URL for Grafana Dashboard"
  value       = "http://${google_dns_record_set.grafana.name}"
}

output "prometheus_url" {
  description = "Access URL for Prometheus (Internal)"
  value       = "http://${google_dns_record_set.prometheus.name}:9090"
}

output "loki_url" {
  description = "Access URL for Loki (Internal)"
  value       = "http://${google_dns_record_set.loki.name}:3100"
}

output "tempo_url" {
  description = "Access URL for Tempo (Internal)"
  value       = "http://${google_dns_record_set.tempo.name}:3200"
}
