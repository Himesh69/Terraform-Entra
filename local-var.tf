locals {
  domain_name = data.azuread_domains.aad.domains.0.domain_name
  users       = csvdecode(file("azure_ad_users.csv"))

  # User map keyed by employee_id (guaranteed unique) - fixes for_each collision
  users_map = { for u in local.users : u.employee_id => u }

  # Flatten each user's semicolon-separated groups into individual membership entries
  # Produces a list of {employee_id, group_name} objects
  user_group_memberships = flatten([
    for u in local.users : [
      for g in split(";", u.groups) : {
        employee_id = u.employee_id
        group_name  = trimspace(g)
      }
    ]
  ])

  # Deduplicated set of all group names from the CSV
  all_groups = toset(distinct([for m in local.user_group_memberships : m.group_name]))
}
