module "automation" {
  source = "../../"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository              = "terraform-spacelift-automation"
  branch                  = "feature/initial-version" # TODO: remove this
  root_modules_path       = "../../examples/complete/components"
  enabled_root_modules    = ["random-pet"]
  aws_integration_enabled = true
  aws_integration_id      = "01J30JBKQTCD72ATZCRWHYST3C"
}
