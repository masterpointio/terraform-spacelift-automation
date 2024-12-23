module "automation" {
  source = "../../../../"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository               = "terraform-spacelift-automation"
  root_modules_path        = "../../../../examples/single-instance/root-modules"
  all_root_modules_enabled = true

  aws_integration_id      = "01JEC7ZACVKHTSVY4NF8QNZVVB"
  aws_integration_enabled = true

  root_module_structure = "SingleInstance"
}
