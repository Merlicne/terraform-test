variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "github_repository" {
  description = "The exact GitHub username/repository name (e.g. phann/my-terraform-infra)"
  type        = string
}
