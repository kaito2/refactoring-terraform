// TODO: Merge Modules
module "cluster" {
  source = "../../modules/cluster"

  project_id = "REPLACE_ME"
  region     = "asia-northeast1"
}

module "network" {
  source = "../../modules/network"

  project_id = "REPLACE_ME"
  region = "asia-northeast1"
}
