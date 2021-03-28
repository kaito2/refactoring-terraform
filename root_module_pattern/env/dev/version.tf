terraform {
  // FIXME: Need required_providers ?
  backend "gcs" {
    prefix = "terraform"
    // TODO: 環境ごとにファイルを分割する
    bucket = "kaito2-flat-pattern-dev"
  }

  required_version = "~> 0.14"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
