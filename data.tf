data "external" "list_root_modules" {
  count = var.enable_all_root_modules ? 1 : 0
  program = [
    "bash", "-c",
    "ls -d ${path.root}/${var.root_modules_path}/*/ | xargs -n 1 basename | jq -R . | jq -s '{\"root_modules\": join(\",\")}' | jq -s '.[0]'"
  ]
}
