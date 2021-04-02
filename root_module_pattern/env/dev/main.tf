// TODO: Merge Modules
module "gcp" {
  source = "../../modules/gcp"

  // TODO: Replace
  project_id = "REPLACE_ME"
  region     = "asia-northeast1"
}
