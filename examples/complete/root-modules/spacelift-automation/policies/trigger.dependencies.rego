package spacelift

import future.keywords.in

# https://docs.spacelift.io/concepts/policy/trigger-policy

# Trigger other stacks (from `input.stacks` list) that depend on the current stack (`input.stack.id`)
# The other stacks must have a label `depends-on:<current_stack_name>` to be triggered after the current stack finishes running
trigger[other_stack.id] {
  other_stack := input.stacks[_]
  input.run.state == "FINISHED"
  input.run.type == "TRACKED"
  input.run.branch == input.stack.branch
  other_stack.labels[_] == concat("", ["depends-on:", input.stack.id])
  some change in input.run.changes
  contains(change.entity.name, other_stack.id)
}

sample = true
