// TODO: Merge Modules
module "gcp" {
  source = "../../modules/gcp"

  // TODO: Replace
  project_id = "YOUR_GCP_PROJECT_ID"
  region     = "asia-northeast1"
}
