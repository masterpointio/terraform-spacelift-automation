locals {
  # Getting these file sets is a bit of a hack because the paths are all sorts of gunked up.
  # We fix this below with the normalize_paths and stack_config_contents locals, but it's goofy.
  multi_instance_stack_configs  = fileset("${path.root}/../**/stacks", "*.yaml")
  single_instance_stack_configs = fileset("${path.root}/../**", "stack.yaml")

  stack_configs = toset(concat(
    tolist(local.multi_instance_stack_configs),
  tolist(local.single_instance_stack_configs)))

  normalize_paths = [
    for stack_config in local.stack_configs :
    replace(stack_config, "../", "")
  ]

  stack_config_contents = {
    for stack_config in local.normalize_paths :
    stack_config => file("./tests/${stack_config}")
  }
}

data "jsonschema_validator" "stack_configs" {
  for_each = local.stack_config_contents

  document = jsonencode(yamldecode(each.value))
  schema   = "${path.module}/../../stack-config.schema.json"
}

output "validated_stack_configs" {
  value = data.jsonschema_validator.stack_configs
}

terraform {
  required_version = ">= 1.7"
  required_providers {
    jsonschema = {
      source  = "bpedman/jsonschema"
      version = ">= 0.2.1"
    }
  }
}
