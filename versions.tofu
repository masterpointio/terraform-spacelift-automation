terraform {
  required_version = ">= 1.8"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = ">= 1.14"
    }
    jsonschema = {
      source  = "bpedman/jsonschema"
      version = ">= 0.2.1"
    }
  }
}
