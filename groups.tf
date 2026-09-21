resource "azuread_group" "groups" {
  for_each = local.all_groups

  display_name     = each.key
  security_enabled = true
}
