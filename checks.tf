/*
 * These check blocks assertions enforce mutual exclusivity between ID and name variables.
 *
 * It took a bit for me to understand the logic, so here's an explanation (with the help with AI):
 * The condition "var.x_id == null || var.x_name == null" is an ASSERTION that must be TRUE.
 * It asserts: "space_id must be null OR space_name must be null" (at least one must be null).
 *
 * When both are set: space_id is NOT null AND space_name is NOT null
 * → false || false = false → ASSERTION FAILS → TF fails (so BOTH shouldn't be set at the same time)
 *
 * When only one is set: one is null, one is not null
 * → true || false = true → ASSERTION PASSES → TF continues (so one can be set, the other can be null)
 *
 * Truth Table:
 * | x_id      | x_name      | Condition Result        | TF Action |
 * |-----------|-------------|-------------------------|------------------|
 * | null      | null        | true || true = true     | ✅ PASS          |
 * | null      | "some-name" | true || false = true    | ✅ PASS          |
 * | "some-id" | null        | false || true = true    | ✅ PASS          |
 * | "some-id" | "some-name" | false || false = false  | ❌ FAIL          |
 */

check "spaces_enforce_exclusivity" {
  assert {
    condition     = var.space_id == null || var.space_name == null
    error_message = "space_id and space_name are mutually exclusive."
  }
}

check "worker_pools_mutual_exclusivity" {
  assert {
    condition     = var.worker_pool_id == null || var.worker_pool_name == null
    error_message = "worker_pool_id and worker_pool_name are mutually exclusive."
  }
}

check "aws_integrations_mutual_exclusivity" {
  assert {
    condition     = var.aws_integration_id == null || var.aws_integration_name == null
    error_message = "aws_integration_id and aws_integration_name are mutually exclusive."
  }
}
