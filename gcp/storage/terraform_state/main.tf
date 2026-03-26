# main.tf

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

# The bucket that will store our Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = var.state_bucket_name
  location      = var.region
  
  # Prevent accidental deletion of this state bucket
  force_destroy = false
  
  # Highly recommended: Enable versioning so you can recover lost state
  versioning {
    enabled = true
  }

  # Recommended: Uniform access control for better security
  uniform_bucket_level_access = true
}

