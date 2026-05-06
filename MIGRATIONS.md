# Migration Guide

## v2.x → v3.0.0

### Overview

v3.0.0 ships two breaking changes:

1. **`root_modules_path` is split** into `root_modules_discovery_path` and `project_root_prefix`, and the silent `../` strip is removed.
2. **MultiInstance stack ID format changes** — the new variable `workspace_prefix_enabled` defaults to `true`, so stack IDs become `${workspace}-${module}` (e.g. `dev-network`) instead of `${module}-${workspace}` (e.g. `network-dev`).

Read both sections below before upgrading.

---

### 1. Path variable split: `root_modules_path` → `root_modules_discovery_path` + `project_root_prefix`

#### Why

`root_modules_path` was overloaded: spacelift-automation needs a filesystem path **relative to the consuming module** to discover stacks, but Spacelift's `project_root` is **relative to the repo root**. v2.x bridged the two by silently stripping leading `../` segments from the variable — that only produced the right `project_root` when the consuming module sat at `<repo>/root-modules/spacelift-automation/`. Any other layout produced a wrong `project_root` with no error, surfacing only as a Spacelift run failure.

v3.0.0 splits the variable into two:

- `root_modules_discovery_path` — discovery path, relative to this module.
- `project_root_prefix` — prefix prepended to `project_root`, relative to the repo root.

The silent `../` strip is gone. If the discovery path contains `..`, you must set `project_root_prefix` explicitly.

#### Replacement table

| v2.x                                                   | v3.0.0                                                                              |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| `root_modules_path = "../../root-modules"`             | `root_modules_discovery_path = "../"` + `project_root_prefix = "root-modules"`      |
| `root_modules_path = "../../stacks"` (remote stacks)   | `root_modules_discovery_path = "../../stacks"` + `project_root_prefix = "stacks"`   |
| `root_modules_path = "root-modules"` (no `..`)         | `root_modules_discovery_path = "root-modules"` (no prefix needed)                   |

If you leave `project_root_prefix` unset while the discovery path contains `..`, `tofu plan` fails with a validation error.

#### How to verify

v3.0.0 exposes each stack's resolved `project_root` on the `spacelift_stacks` output. Run `tofu plan` and inspect — if every value matches the v2.x `project_root`, no stack replacements occur.

---

### 2. MultiInstance stack ID format flip: `workspace_prefix_enabled`

#### Why

The new default puts the workspace (environment) component **before** the root module name. This matches the conventions used by `context.tf` and label naming throughout the masterpoint ecosystem — context-identifying information first, the actual resource name last — so similar stacks group naturally when sorted/filtered in the Spacelift UI.

#### What changed

| Item                                       | v2.x                                          | v3.0.0                                                              |
| ------------------------------------------ | --------------------------------------------- | ------------------------------------------------------------------- |
| MultiInstance stack ID format (default)    | `${module}-${workspace}` (e.g. `network-dev`) | `${workspace}-${module}` (e.g. `dev-network`)                       |
| `workspace_prefix_enabled` module variable | N/A (hardcoded format)                        | New `bool`, defaults to `true`. Set to `false` to keep v2.x format. |
| Folder labels and dependency labels        | Unchanged                                     | Unchanged                                                           |
| SingleInstance stack IDs                   | `${module}`                                   | Unchanged — variable does not apply.                                |

> **Heads up:** Spacelift identifies stacks by ID. Renaming a stack ID destroys the old stack and creates a new one — state, run history, environment variables, and attachments do not transfer automatically. Plan the migration before you apply.

#### Migration options

##### Option A — Keep the v2.x naming (recommended for existing deployments)

Set `workspace_prefix_enabled = false` in your module call. No stack IDs change, no recreation, no plan diff related to stack naming.

```hcl
module "spacelift_automation" {
  source  = "masterpointio/automation/spacelift"
  version = "3.0.0"

  workspace_prefix_enabled = false # ${module}-${workspace} -> e.g. serviceA-dev
  # ... rest of your config
}
```

You can adopt the new default later when you're ready to recreate stacks.

##### Option B — Adopt the new default (recreate stacks with workspace-first IDs)

THIS IS A BIG LIFT AND HIGHLY RISKY. WE DO NOT RECOMMEND THIS OPTION UNLESS NECESSARY AND YOU HAVE A GOOD MIGRATION PLAN IN PLACE TO EXECUTE THIS.

Accept the new default, run `tofu plan`, and confirm the diff shows every MultiInstance stack being destroyed and recreated with the new ID. Also note that there will be other dependencies, such as between Spacelift stacks, or stack deletion protection. Before applying:

1. Inventory anything that references stack IDs by string (CI workflows, drift webhook URLs, dashboards, run trigger labels, dependency labels in YAML, external scripts).
2. Update those references in lockstep with the apply.
3. If state continuity matters, follow the Spacelift docs for migrating stack state across renames or use `terraform state mv` against the Spacelift state.

#### How to verify

After upgrading and applying, inspect a sample stack:

- `tofu state show 'module.spacelift_automation.spacelift_stack.default["dev-network"]'` — Option B
- `tofu state show 'module.spacelift_automation.spacelift_stack.default["network-dev"]'` — Option A (unchanged)

The `terraform_workspace`, `project_root`, folder labels, and dependency labels should all remain identical to v2.x.

---

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
