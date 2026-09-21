data "azuread_domains" "aad" {
  only_initial = true
}

resource "random_password" "user_passwords" {
  for_each = local.users_map

  length           = 24
  special          = true
  override_special = "!@#$%&*"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azuread_user" "users" {
  for_each = local.users_map

  # UPN built from CSV username + tenant domain
  user_principal_name = "${each.value.username}@${local.domain_name}"

  display_name          = each.value.display_name
  mail_nickname         = each.value.username
  password              = random_password.user_passwords[each.key].result
  force_password_change = true
  account_enabled       = lower(each.value.account_enabled) == "true"
  department            = each.value.department
  job_title             = each.value.job_title
}
