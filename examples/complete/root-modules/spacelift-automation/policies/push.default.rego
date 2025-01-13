# Based on https://github.com/cloudposse/terraform-spacelift-cloud-infrastructure-automation/blob/main/catalog/policies/git_push.default.rego

# https://docs.spacelift.io/concepts/policy/git-push-policy

package spacelift

# Get all affected files
# `input.push.affected_files` contains a list of file names (relative to the project root)
# that were changed in the current push to the branch
affected_files := input.push.affected_files

# Track these extensions in the project folder
tracked_extensions := {".tf", ".tf.json", ".lock.hcl", ".yaml", ".yml", ".tpl", ".sh", ".shell", ".bash"}

project_root := input.stack.project_root

# Check if any of the tracked extensions were modified in the project folder
# https://www.openpolicyagent.org/docs/latest/policy-language/#some-keyword
# https://www.openpolicyagent.org/docs/latest/policy-language/#variable-keys
# https://www.openpolicyagent.org/docs/latest/policy-reference/#iteration
project_affected {
  some i, j
  startswith(affected_files[i], project_root)
  endswith(affected_files[i], tracked_extensions[j])
}

# Specific rules for the stack "spacelift-automation" to track tfvars files and configs
track_tfvars_files {
  startswith(input.stack.id, "spacelift-automation")
  some i
  startswith(affected_files[i], "root-modules")
  endswith(affected_files[i], ".tfvars")
}

# Track yaml changes in root-modules `stacks/*.yaml` to always trigger spacelift-automation
track_root_yaml_changes {
  some i
  startswith(affected_files[i], "root-modules")
  endswith(affected_files[i], ".yaml")
}

track_spacelift_policies {
  startswith(input.stack.id, "spacelift-policies")
  some i
  endswith(affected_files[i], ".rego")
}

track_child_modules {
  some i
  startswith(affected_files[i], "child-modules")
  endswith(affected_files[i], tracked_extensions[j])
}

some_tfvars_file_relates_to_stack {
  some i
  affected_file := affected_files[i]
  endswith(affected_file, ".tfvars")
  path_parts := split(affected_file, "/")
  tfvars_file := path_parts[count(path_parts) - 1]
  file_name := trim_suffix(tfvars_file, ".tfvars")
  contains(input.stack.name, file_name)
}

# Propose a run if component's files are affected
# https://docs.spacelift.io/concepts/run/proposed
propose {
  project_affected
}

track {
  some_tfvars_file_relates_to_stack
  input.push.branch == input.stack.branch
}

# Track if project files are affected and the push was to the stack's tracked branch
# https://docs.spacelift.io/concepts/run/tracked
track {
  project_affected
  input.push.branch == input.stack.branch
}

track {
  track_tfvars_files
  input.push.branch == input.stack.branch
}

# Add to track rule to trigger spacelift-automation when yaml changes occur
track {
  track_root_yaml_changes
  startswith(input.stack.id, "spacelift-automation")
  input.push.branch == input.stack.branch
}

track {
  track_child_modules
  input.push.branch == input.stack.branch
}

track {
  track_spacelift_policies
  input.push.branch == input.stack.branch
}

# Ignore if nothing is affected
ignore {
  not project_affected
  not track_tfvars_files
  not track_child_modules
  not track_spacelift_policies
  not some_tfvars_file_relates_to_stack
}

ignore {
  input.push.tag != ""
}

sample = true
