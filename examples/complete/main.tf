module "automation" {
  source = "../../modules/spacelift-automation/"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository           = "terraform-spacelift-automation"
  branch               = "feature/initial-version" # TODO: remove this
  root_modules_path    = "../../examples/complete/components"
  enabled_root_modules = ["random-pet"]
  aws_integration_id   = "01J30JBKQTCD72ATZCRWHYST3C"
}
