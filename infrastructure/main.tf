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

## LOAD BALANCER SET UP
# Create an external IP to use for our load balancer
resource "google_compute_global_address" "global_lb_ipv4" {
  name         = "global-lb-ipv4"
  address_type = "EXTERNAL"
  project      = var.project_id
  ip_version   = "IPV4"

}

# Serverless NEG
resource "google_compute_region_network_endpoint_group" "cloundrun_neg" {
  name                  = "my-cloudrun-neg"
  region                = "us-west2"
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.unity_container_run.name
  }
}

# SSL cert to use for our load balancer
resource "google_compute_managed_ssl_certificate" "cloundrun_lb_cert" {
  provider = google-beta
  name     = "my-ssl-cert"
  managed {
    domains = [var.domain_name]
  }
}

# The actual backend service
resource "google_compute_backend_service" "cloudrun_backend" {
  name                            = "my-unity-backend"
  protocol                        = "HTTP"
  port_name                       = "http"
  enable_cdn                      = false
  connection_draining_timeout_sec = 10
  security_policy = google_compute_security_policy.cloudrun_security_policy.name

  backend {
    group = google_compute_region_network_endpoint_group.cloundrun_neg.id
  }
}

# URL map for routing (just having a default here)
resource "google_compute_url_map" "cloudrun_url_map" {
  name            = "my-unity-url-map"
  default_service = google_compute_backend_service.cloudrun_backend.id
}

# HTTP Proxy to tie together our URL map withthe SSL cert
resource "google_compute_target_https_proxy" "cloudrun_https_proxy" {
  name             = "my-unity-https-proxy"
  url_map          = google_compute_url_map.cloudrun_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cloundrun_lb_cert.id]
}

# Forwarding rule
resource "google_compute_global_forwarding_rule" "cloudrun_https_rule" {
  name                  = "my-unity-https-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.cloudrun_https_proxy.id
  ip_address            = google_compute_global_address.global_lb_ipv4.id
}

#### Cloud Armor Settings ####
resource "google_compute_security_policy" "cloudrun_security_policy" {
  name = "my-cloudarmor-policy"
}

resource "google_compute_security_policy_rule" "rate_throttle" {
  security_policy = google_compute_security_policy.cloudrun_security_policy.name
  description     = "Used to throttle rate request per source IP"
  action          = "throttle"
  priority        = 1000

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }

  rate_limit_options {
    rate_limit_threshold {
      count        = 200
      interval_sec = 60
    }

    conform_action = "allow"
    exceed_action  = "deny(429)"
    enforce_on_key = "IP"
  }
}