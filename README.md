# Terraform Entra ID — Automated User & Group Provisioning

Automates bulk provisioning of **Microsoft Entra ID** (Azure AD) users, security groups, and group memberships from a single CSV file using **Terraform**.

---

## Architecture

```
azure_ad_users.csv
        │
        ▼
┌───────────────┐     ┌──────────────────────┐     ┌──────────────────────────┐
│  local-var.tf │────▶│  user-creation.tf    │────▶│  group-membership.tf     │
│               │     │  • azuread_user ×50  │     │  • azuread_group_member  │
│  • users_map  │     │  • random_password   │     │    (per user-group pair) │
│  • all_groups │     └──────────────────────┘     └──────────────────────────┘
│  • memberships│                                          ▲
└───────┬───────┘     ┌──────────────────────┐             │
        └────────────▶│  groups.tf           │─────────────┘
                      │  • azuread_group ×13 │
                      └──────────────────────┘
                      ┌──────────────────────┐
                      │  password-export.tf  │
                      │  • user_credentials  │──▶  user_credentials.csv
                      │    (sensitive file)   │
                      └──────────────────────┘
```

---

## Features

- **CSV-driven** — Add, remove, or update users by editing a single CSV file
- **Unique keying** — Users are keyed by `employee_id`, eliminating collisions from duplicate names
- **Dynamic groups** — All groups are auto-discovered from the CSV `groups` column (no hardcoding)
- **Multi-group membership** — Semicolon-separated groups (e.g. `grp-allstaff;grp-engineering`) are parsed and assigned automatically
- **Secure passwords** — 24-character random passwords via `random_password` (forced change on first login)
- **Credentials export** — Passwords are written to a local `user_credentials.csv` using `local_sensitive_file` (hidden from plan output)
- **Account control** — `account_enabled` column in CSV directly controls whether the user account is active or disabled
- **Remote state** — Terraform state is stored in Azure Blob Storage (`azurerm` backend)

---

## Prerequisites

| Requirement | Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | `>= 1.5` |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | `>= 2.50` |
| Microsoft Entra ID tenant | With admin consent for user/group management |
| Azure Storage Account | For remote state backend |

### Required Terraform Providers

| Provider | Version | Purpose |
|---|---|---|
| `hashicorp/azuread` | `~> 3.9.0` | Entra ID user & group management |
| `hashicorp/random` | `~> 3.6` | Secure password generation |
| `hashicorp/local` | `~> 2.5` | Credentials file export |

---

## Project Structure

```
Terraform-Entra/
├── azure_ad_users.csv        # Source of truth — all user data
├── local-var.tf              # Locals: user map, group list, membership pairs
├── user-creation.tf          # azuread_user + random_password resources
├── groups.tf                 # azuread_group — dynamic from CSV
├── group-membership.tf       # azuread_group_member — per user-group pair
├── password-export.tf        # local_sensitive_file → user_credentials.csv
├── output.tf                 # Terraform outputs (UPNs, groups, creds path)
├── provider.tf               # Provider declarations
├── backend.tf                # Remote state backend (Azure Blob Storage)
├── service_principle.sh      # Helper script to create Azure SP + export ARM_* vars
├── .gitignore                # Excludes state, credentials, and sensitive files
└── README.md                 # This file
```

---

## CSV Format

The `azure_ad_users.csv` file is the single source of truth. It must contain the following columns:

| Column | Description | Example |
|---|---|---|
| `employee_id` | Unique identifier (used as Terraform resource key) | `EMP1001` |
| `username` | Login username (used to build UPN) | `saanvi.mehta` |
| `display_name` | Full display name | `Saanvi Mehta` |
| `email` | Email address | `saanvi.mehta@corptechsol.com` |
| `user_principal_name` | Reference UPN from source system | `saanvi.mehta@corptechsol.com` |
| `department` | Department name | `Finance` |
| `job_title` | Job title | `Financial Analyst` |
| `location` | Office location | `Mumbai` |
| `manager_email` | Manager's email | `manager.finance@corptechsol.com` |
| `groups` | Semicolon-separated group names | `grp-allstaff;grp-engineering` |
| `account_enabled` | Account status (`TRUE` / `FALSE`) | `TRUE` |

### Example

```csv
employee_id,username,display_name,email,user_principal_name,department,job_title,location,manager_email,groups,account_enabled
EMP1001,saanvi.mehta,Saanvi Mehta,saanvi.mehta@corptechsol.com,saanvi.mehta@corptechsol.com,Finance,Financial Analyst,Mumbai,manager.finance@corptechsol.com,grp-finance,TRUE
EMP1002,aarav.nair,Aarav Nair,aarav.nair@corptechsol.com,aarav.nair@corptechsol.com,Engineering,QA Engineer,Mumbai,manager.engineering@corptechsol.com,grp-allstaff;grp-engineering,TRUE
```

---

## Getting Started

### 1. Authenticate

Use the included helper script to create a Service Principal and export environment variables:

```bash
source service_principle.sh
```

This will:
- Log you into Azure CLI
- Create a Service Principal with `Contributor` role
- Export `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, and `ARM_TENANT_ID`

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Preview Changes

```bash
terraform plan
```

Expected resources on first run:

| Resource | Count |
|---|---|
| `random_password.user_passwords` | 50 |
| `azuread_user.users` | 50 |
| `azuread_group.groups` | 13 |
| `azuread_group_member.memberships` | ~67 |
| `local_sensitive_file.user_credentials` | 1 |

### 4. Apply

```bash
terraform apply
```

After apply, the credentials file is written to `./user_credentials.csv`:

```csv
employee_id,username,user_principal_name,password
EMP1001,saanvi.mehta,saanvi.mehta@<tenant>.onmicrosoft.com,xK#9pLm...
```

> **⚠️ Security**: This file contains plaintext passwords. It is excluded from Git via `.gitignore`. Distribute credentials securely and delete the file after use.

---

## Adding / Removing Users

1. **Add a user** — Append a new row to `azure_ad_users.csv`
2. **Remove a user** — Delete the row from `azure_ad_users.csv`
3. **Change groups** — Edit the `groups` column (semicolon-separated)
4. **Disable an account** — Set `account_enabled` to `FALSE`
5. Run `terraform plan` to preview, then `terraform apply`

---

## Security Considerations

| Concern | Mitigation |
|---|---|
| Passwords in state file | State is stored in encrypted Azure Blob Storage backend |
| Passwords in plan output | `local_sensitive_file` suppresses content from CLI output |
| Credentials file on disk | Restricted to `0600` permissions; excluded from `.gitignore` |
| First-login security | `force_password_change = true` on all accounts |
| Predictable passwords | `random_password` with 24 chars, mixed case, numbers, symbols |

---

## Outputs

| Output | Description |
|---|---|
| `domain` | Tenant's initial domain name |
| `user_principal_names` | Map of `employee_id` → UPN for all created users |
| `groups_created` | List of all group display names |
| `credentials_file` | Path to the generated `user_credentials.csv` |

---

## License

This project is provided as-is for internal infrastructure automation.
