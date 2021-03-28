terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  backend "gcs" {
    prefix = "terrform"
    // TODO: 環境ごとにファイルを分割する
    bucket = "kaito2-flat-pattern-dev"
  }

  required_version = "~> 0.14"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
