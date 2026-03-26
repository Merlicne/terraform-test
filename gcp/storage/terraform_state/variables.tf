variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "asia-southeast1"
}

variable "state_bucket_name" {
  description = "The name of the GCS bucket for Terraform state"
  type        = string
}
