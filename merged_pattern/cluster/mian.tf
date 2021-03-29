// FIXME: Don't use terraform_remote_state to avoid implicit dependency.
data "terraform_remote_state" "network" {
  backend   = "gcs"
  workspace = "network"

  config = {
    bucket = "kaito2-flat-pattern-dev"
    prefix = "terraform"
  }
}

resource "google_container_cluster" "primary" {
  name     = "terraform-sample"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = data.terraform_remote_state.network.outputs.vpc_name
  subnetwork = data.terraform_remote_state.network.outputs.subnet_name

  master_auth {
    // Disable basic auth
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "terraform-sample"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "n1-standard-1"
    tags = [
      "gke-node",
      var.project_id,
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
