output "domain" {
  value = local.domain_name
}

output "user_principal_names" {
  value = { for k, u in azuread_user.users : k => u.user_principal_name }
}

output "groups_created" {
  value = [for k, g in azuread_group.groups : g.display_name]
}

output "credentials_file" {
  value = local_sensitive_file.user_credentials.filename
}
