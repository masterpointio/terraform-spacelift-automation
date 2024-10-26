locals {
  # Read and decode stack YAML files from the root directory
  root_module_yaml_decoded = {
    for module in var.enabled_root_modules : module => {
      for yaml_file in fileset("${path.root}/${var.root_modules_path}/${module}/stacks", "*.yaml") :
      yaml_file => yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stacks/${yaml_file}"))
    }
  }

  # Retrieve common stack configurations for each root module
  common_configs = {
    for module, file in local.root_module_yaml_decoded : module => lookup(file, "common.yaml", {})
  }

  # Merge all stack configurations from the root modules into a single map
  #stack_configs = local.root_module_stack_configs
  root_module_stack_configs = merge([for module, files in local.root_module_yaml_decoded : {
    for file, content in files : "${module}-${trimsuffix(file, ".yaml")}" =>
    merge(
      {
        "project_root"        = replace(format("%s/%s", var.root_modules_path, module), "../", "")
        "root_module"         = module,
        "terraform_workspace" = trimsuffix(file, ".yaml"),
      },
      content
    ) if file != "common.yaml"
    }
  ]...)

  configs = {
    for key, value in module.deep : key => value.merged
  }

  stack_configs = {
    for key, value in local.configs : key => try(value.stack_settings, {})
  }
}

# Merge stack configurations with the common configurations
module "deep" {
  source   = "cloudposse/config/yaml//modules/deepmerge"
  version  = "1.0.2"
  for_each = local.root_module_stack_configs
  maps     = [each.value, local.common_configs[each.value.root_module]]
}
