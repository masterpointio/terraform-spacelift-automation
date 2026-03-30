# Migration Guide

## v1.x → v2.0.0

### Overview

Spacelift is deprecating the `administrative` stack flag on **June 1, 2026**. v2.0.0 removes all support for that flag and replaces it with the `spacelift_role_attachment` resource, which provides equivalent permissions plus new capabilities like cross-space access and fine-grained custom roles.

### Breaking changes

| What changed                       | v1.x                                             | v2.0.0                                                   |
| ---------------------------------- | ------------------------------------------------ | -------------------------------------------------------- |
| `administrative` module variable   | `var.administrative = true`                      | Removed — use `var.role_attachment`                      |
| `administrative` YAML key          | `stack_settings.administrative: true`            | Removed — use `stack_settings.role_attachment_role_slug` |
| `administrative` output attribute  | `spacelift_stacks["name"].administrative`        | Removed                                                  |
| `"administrative"` auto-label      | Added automatically when `administrative = true` | No longer generated                                      |
| Spacelift provider minimum version | `>= 1.14`                                        | `>= 1.37` (required for stack role attachments)          |

### Preparing for migration: the chicken-and-egg problem

Before running the v2.0.0 migration, you need to ensure your managing stack has a role attachment in the root space with at least `space-writer` privilege. Here is why:

- Role attachments can be created while `administrative = true` is set, but they do not take effect until `administrative` is removed.
- v2.0.0 removes `administrative` and adds `role_attachment_role_slug: space-admin`. The moment `administrative` is removed, the stack needs an already-active role to have privilege to create the new role bindings. With none in place, the apply fails: `could not create stack role binding: unauthorized`.

**Why `space-writer` and not `space-admin`?**

Per the migration guide, you add `role_attachment_role_slug: space-admin` to your managing stack's YAML when upgrading to v2.0.0. If you pre-attached `space-admin` as the stepping-stone, the apply fails with a conflict: `could not create stack role bindings: stack role binding already exists for this role, space and stack combination`. Using `space-writer` avoids the conflict — it grants sufficient privilege to create role bindings without colliding with the `space-admin` attachment v2.0.0 creates.

**Resolution options:**

**Option A — Spacelift UI (no intermediate release needed):**

Before upgrading to v2.0.0, manually add a `space-writer` role attachment to your managing stack in the root space via the Spacelift UI. After the v2.0.0 migration applies successfully, remove the `space-writer` attachment.

**Option B — v1.10.0 stepping stone:**

1. Upgrade to v1.10.0. Keep `administrative: true` in your YAML — do not remove it yet.
2. Add `space-writer` to your managing stack in the root space using `var.role_attachment`:

   ```hcl
   module "spacelift_automation" {
     source  = "masterpointio/automation/spacelift"
     version = "1.10.0"

     role_attachment = {
       role_slug = "space-writer"
       space_id  = "root"
     }
     # ... rest of your config, keep administrative: true in YAML
   }
   ```

3. Apply. The `space-writer` attachment is created (inactive while `administrative` is still set).
4. Upgrade to v2.0.0, replace `administrative: true` with `role_attachment_role_slug: space-admin` in your YAML, and apply.
5. After the v2.0.0 apply completes successfully, remove the `space-writer` `role_attachment` config and apply once more to clean up.

### Migration steps

#### 1. Upgrade the Spacelift Terraform provider

Stack role attachments require provider `>= 1.37`. Update your lock file:

```shell
tofu init -upgrade
# or
terraform init -upgrade
```

#### 2. Update stack config YAML files

Replace `administrative: true` under `stack_settings` with `role_attachment_role_slug` set to the slug of the role you want to attach. Setting the slug is all that is needed — its presence creates the `spacelift_role_attachment` resource for that stack:

```yaml
# Before
kind: StackConfigV1
stack_settings:
  administrative: true

# After
kind: StackConfigV1
stack_settings:
  role_attachment_role_slug: "space-admin"
```

To attach in a space other than the stack's own space, add `role_attachment_space_id`:

```yaml
kind: StackConfigV1
stack_settings:
  role_attachment_role_slug: "space-admin"
  role_attachment_space_id: "some-space-id"
```

Simply removing `administrative: false` entries requires no replacement — no attachment is created when `role_attachment_role_slug` is absent.

#### 3. Update module-level variable calls

If you were setting `administrative = true` at the module level (applying to all stacks):

```hcl
# Before
module "spacelift_automation" {
  source  = "masterpointio/automation/spacelift"
  version = "1.8.0"

  administrative = true
  # ...
}

# After
module "spacelift_automation" {
  source  = "masterpointio/automation/spacelift"
  version = "2.0.0"

  role_attachment = {
    role_slug = "space-admin"
    # space_id = null  # optional: defaults to each stack's own space
  }
  # ...
}
```

Setting `var.role_attachment` applies a role attachment to **all stacks** managed by that module instance. Per-stack `role_attachment_role_slug` in YAML overrides the module-level slug for that stack.

#### 4. Update any policy references to the `"administrative"` label

The `"administrative"` label was previously auto-generated for stacks with `administrative = true`. If your Spacelift push/approval/notification policies filter on this label, either:

- Add it back manually via `stack_settings.labels: ["administrative"]` in your YAML, or
- Update the policy to use a different signal.

#### 5. Remove references to the removed output attribute

The `administrative` attribute has been removed from the `spacelift_stacks` output map. If anything downstream reads `module.spacelift_automation.spacelift_stacks["name"].administrative`, remove that reference.

### New capabilities in v2.0.0

The new role attachment system unlocks functionality that the old flag could not provide:

- **Cross-space access** — set `role_attachment_space_id` to a sibling space ID to grant the stack permissions outside its own space hierarchy.
- **Fine-grained roles** — attach any built-in or custom role slug defined in your Spacelift account, scoped to precisely the permissions your stack needs.
- **Per-stack overrides** — module-level `var.role_attachment` applies to all stacks, individual stacks can set their own `role_attachment_role_slug` to use a different role.
- **Managed role creation** — use `var.managed_roles` to create custom Spacelift roles (with specific `actions`) directly from this module, then reference them by their map key in `var.role_attachment.role_slug` or per-stack `role_attachment_role_slug`. This replaces the need to create roles manually in the Spacelift UI before referencing them.

  ```hcl
  managed_roles = {
    "ci-deployer" = {
      name        = "CI Deployer"
      description = "Least-privilege role for CI stacks — can read spaces and trigger runs"
      actions     = ["SPACE_READ", "RUN_TRIGGER"]
    }
  }

  role_attachment = {
    role_slug = "ci-deployer"  # references the managed_roles key above
  }
  ```
