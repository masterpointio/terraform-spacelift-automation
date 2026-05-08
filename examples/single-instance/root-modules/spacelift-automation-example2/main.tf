module "automation" {
  source = "../../../../"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository = "terraform-spacelift-automation"

  # discovery_path is relative to THIS module — siblings (random-pet/, rds-cluster-*/) live
  # one level up. project_root_prefix is the repo-root-relative path Spacelift records.
  root_modules_discovery_path = ".."
  project_root_prefix         = "examples/single-instance/root-modules"
  all_root_modules_enabled    = true

  aws_integration_id      = "01JEC7ZACVKHTSVY4NF8QNZVVB"
  aws_integration_enabled = true

  root_module_structure = "SingleInstance"
}
