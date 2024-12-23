module "automation" {
  source = "../../../../"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository               = "terraform-spacelift-automation"
  root_modules_path        = "../../../../examples/single-instance/root-modules"
  all_root_modules_enabled = true
  aws_integration_enabled  = false

  root_module_structure = "SingleInstance"
}
