aws_role_arn = "arn:aws:iam::755965222190:role/Spacelift"

# GitHub configuration
github_enterprise = {
  namespace = "masterpointio"
}
repository = "spacelift-certification"

# Stacks configurations
root_modules = {
  spacelift-aws-role = {
    stacks = {
      automation = {
        description = "The AWS IAM role to assume and put its temporary credentials in `masterpoint-automation` in the runtime environment."
        space_id    = "mp-automation-01J2BSSM6TW46GJ6EJNZW1WP2B"
      }
    }
  }
  spacelift-spaces = {
    stacks = {
      mp-automation = {
        administrative = true
        description    = "Spacelift space for all non-administrative resources for masterpoint-automation."
      }
    }
  }
  spacelift-automation = {
    stacks = {
      mp-main = {
        administrative = true
        description    = "Administrative Spacelift Stack for managing Masterpoint's infrastructure for internal projects."
      }
    }
  }
  spacelift-policies = {
    common_stack_configs = {
      administrative = true
    }
    stacks = {
      push-default = {
        description = "Default Push Policy."
      }
      trigger-administrative = {
        description = "Policy to trigger the stack after it gets created in the `administrative` stack."
      }
      trigger-dependencies = {
        description = "Policy to trigger other stacks that depend on the current stack based on the label `depends-on:`"
      }
      plan-iam-policy-modify = {
        description = "Plan policy used to raise a warning for any modification made to aws_iam_policy resources."
      }
      approval-iam-policy-modify = {
        description = "Approval policy used by Security team to approve aws_iam_policy resource changes. Conditionally dependent on the plan-iam-policy-modify Plan policy."
      }
    }
  }
  kms-key = {
    common_stack_configs = {
      space_id = "mp-automation-01J2BSSM6TW46GJ6EJNZW1WP2B"
    }
    # stacks = {
    #   sops-key = {
    #     space_id    = "mp-automation-01J2BSSM6TW46GJ6EJNZW1WP2B"
    #     description = "The key to encrypt/decrypt SOPS secrets."
    #   }
    # }
  }
  spacelift-blueprint = {
    common_stack_configs = {
      administrative = true
    }
    stacks = {
      aws-integration = {
        description = "Blueprint to create stacks for AWS Integration."
      }
    }
  }
}
