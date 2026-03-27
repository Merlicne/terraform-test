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
# 1. Enable Required API
# ------------------------------------------------------------------------------
resource "google_project_service" "iamcredentials" {
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# 2. CI/CD Service Account
# ------------------------------------------------------------------------------
resource "google_service_account" "terraform_ci" {
  account_id   = "terraform-ci"
  display_name = "Terraform CI/CD Service Account"
}

# Grant the Service Account broad permissions so it can manage your infrastructure.
# (If Terraform needs to create OTHER service accounts or IAM roles, it needs projectIamAdmin)
resource "google_project_iam_member" "terraform_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_ci.email}"
}

resource "google_project_iam_member" "terraform_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.terraform_ci.email}"
}

# ------------------------------------------------------------------------------
# 3. Workload Identity Pool
# ------------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions CI/CD"
  disabled                  = false
}

# Create the Provider pointing to GitHub's exact token issuer
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "GitHub Actions Provider"
  
  # How GCP maps the claims from GitHub's JWT token
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  attribute_condition = "assertion.repository == \"${var.github_repository}\""
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ------------------------------------------------------------------------------
# 4. Bind the GitHub Repository to the Service Account
# ------------------------------------------------------------------------------
# CRITICAL SECURITY RULE: Tells GCP that ONLY tokens originating from your 
# specific GitHub Repository are allowed to impersonate the terraform_ci Service Account.
resource "google_service_account_iam_member" "github_actions_oidc_binding" {
  service_account_id = google_service_account.terraform_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repository}"
}
