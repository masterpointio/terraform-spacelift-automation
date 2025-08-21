# Confirm our StackConfig files in fixtures follow the schema.
# If this test fails, check the schema!
run "test_stack_configs_schema_validation" {
  command = plan

  module {
    source = "./tests/schema-validator"
  }

  assert {
    condition     = length(data.jsonschema_validator.stack_configs) == 8
    error_message = "The fixture Stack Configs did not validate against the schema: ${jsonencode(data.jsonschema_validator.stack_configs)}"
  }
}
