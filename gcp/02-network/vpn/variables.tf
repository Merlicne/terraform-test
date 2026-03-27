variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "asia-southeast1"
}

variable "environment" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "tailscale_auth_key" {
  description = "The reusable auth key generated from the Tailscale Admin Console"
  type        = string
  sensitive   = true # Ensures the key doesn't get printed in the console
}
