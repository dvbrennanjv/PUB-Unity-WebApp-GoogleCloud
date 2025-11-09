# for storing our docker images
resource "google_artifact_registry_repository" "unity-repo" {
  location      = "us-west2"
  repository_id = "my-new-repo"
  description   = "Used for unity docker containers"
  format        = "DOCKER"
}