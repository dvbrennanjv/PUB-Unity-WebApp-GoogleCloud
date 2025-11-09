variable "cloudrun_container" {
  type    = string
  default = "us-west2-docker.pkg.dev/PROJECT-ID/REPO-NAME/IMAGE-NAME"
}

variable "project_id" {
  type    = string
  default = "my-project-83823412"
}

variable "region" {
  type    = string
  default = "us-west2"
}

variable "domain_name" {
  type    = string
  default = "app.domain.com"
}

variable "backend_bucket_name" {
  type    = string
  default = "my-tf-gcp-backend"
}