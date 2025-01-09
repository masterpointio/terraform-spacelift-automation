module "automation" {
  source = "../../../../"

  github_enterprise = var.github_enterprise
  repository        = var.repository
  branch            = var.branch

  root_modules_path        = var.root_modules_path
  all_root_modules_enabled = var.all_root_modules_enabled

  aws_integration_id      = var.aws_integration_id
  aws_integration_enabled = true

  labels = var.labels
}
