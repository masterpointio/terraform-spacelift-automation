terraform {
  required_version = ">= 1.6"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = ">= 1.14"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}
