module "automation" {
  source = "../../../../"

  github_enterprise = var.github_enterprise
  repository        = var.repository
  branch            = var.branch

  root_modules_path       = var.root_modules_path
  enable_all_root_modules = var.enable_all_root_modules

  aws_integration_id = var.aws_integration_id
}
