output "workload_identity_provider" {
  description = "The exact string to paste into GitHub Actions YAML for the provider"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "The service account email to paste into GitHub Actions YAML"
  value       = google_service_account.terraform_ci.email
}
