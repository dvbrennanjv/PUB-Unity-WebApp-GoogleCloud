# for storing our docker images
resource "google_artifact_registry_repository" "unity-repo" {
  location      = "us-west2"
  repository_id = "my-new-repo"
  description   = "Used for unity docker containers"
  format        = "DOCKER"
}

# the actual cloud run service that runs our containers
resource "google_cloud_run_v2_service" "unity_container_run" {
  name                = "my-new-cloudrun-service"
  location            = "us-west2"
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  scaling {
    min_instance_count = 0
    max_instance_count = 3
  }

  template {
    containers {
      image = var.cloudrun_container
      ports {
        container_port = 8080
      }
    }
  }
}

# Allows our service to be public
resource "google_cloud_run_v2_service_iam_member" "allow_public" {
  project  = google_cloud_run_v2_service.unity_container_run.project
  location = google_cloud_run_v2_service.unity_container_run.location
  name     = google_cloud_run_v2_service.unity_container_run.name
  role     = "roles/run.invoker"
  member   = "allUsers"

}