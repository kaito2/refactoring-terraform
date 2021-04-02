terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  required_version = "0.14.4"
}

// FIXME: module 内に provider を定義するべきではない?
provider "google" {
  project = var.project_id
  region  = var.region
}
