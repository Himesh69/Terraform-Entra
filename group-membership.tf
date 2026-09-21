resource "azuread_group_member" "memberships" {
  for_each = {
    for m in local.user_group_memberships :
    "${m.employee_id}-${m.group_name}" => m
  }

  group_object_id  = azuread_group.groups[each.value.group_name].object_id
  member_object_id = azuread_user.users[each.value.employee_id].object_id
}
