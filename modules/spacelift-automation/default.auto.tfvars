enabled = true

# For testing:
#aws_role_arn = "arn:aws:iam::755965222190:role/Spacelift" # Need to replace with AWS integration

github_enterprise = {
  namespace = "masterpointio"
}
repository           = "terraform-spacelift-automation"
branch = "feature/initial-version"

root_modules_path    = "../../examples/complete/components"
enabled_root_modules = ["spacelift-policies", "random-pet"]
aws_integration_id = "01J30JBKQTCD72ATZCRWHYST3C"
