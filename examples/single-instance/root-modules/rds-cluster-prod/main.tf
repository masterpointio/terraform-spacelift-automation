resource "null_resource" "example" {
  triggers = {
    timestamp = timestamp()
  }
}
