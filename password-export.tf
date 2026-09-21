resource "local_sensitive_file" "user_credentials" {
  filename = "${path.module}/user_credentials.csv"

  content = join("\n", concat(
    ["employee_id,username,user_principal_name,password"],
    [
      for k, u in local.users_map :
      "${k},${u.username},${azuread_user.users[k].user_principal_name},${random_password.user_passwords[k].result}"
    ]
  ))

  file_permission = "0600"
}
