// TODO: Merge Modules
module "gcp" {
  source = "../../modules/gcp"

  project_id = "REPLACE_ME"
  region     = "asia-northeast1"
}
