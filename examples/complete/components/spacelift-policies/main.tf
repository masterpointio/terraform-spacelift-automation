locals {
  enabled = module.this.enabled
}

module "policy" {
  source  = "cloudposse/cloud-infrastructure-automation/spacelift//modules/spacelift-policy"
  version = "1.6.0"

  count = local.enabled ? 1 : 0

  policy_name      = module.this.name
  body             = try(file(var.body_path), null)
  body_url         = var.body_url
  body_url_version = var.body_url_version
  type             = var.type
  labels           = var.labels
  space_id         = var.space_id
}
