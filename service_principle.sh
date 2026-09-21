#!/usr/bin/env bash
set -e

# 1. Login (if not already)
az login

# 2. Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription: $SUBSCRIPTION_ID"

# 3. Create SP with Contributor role at subscription scope
SP_JSON=$(az ad sp create-for-rbac \
  --name "sp-terraform-$(date +%s)" \
  --role="Contributor" \
  --scopes="/subscriptions/$SUBSCRIPTION_ID" \
  --output json)

# 4. Extract values
APP_ID=$(echo $SP_JSON | jq -r '.appId')
PASSWORD=$(echo $SP_JSON | jq -r '.password')
TENANT=$(echo $SP_JSON | jq -r '.tenant')

# 5. Export as Terraform-recognized ARM_* env vars
export ARM_CLIENT_ID="$APP_ID"
export ARM_CLIENT_SECRET="$PASSWORD"
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_TENANT_ID="$TENANT"

echo "SP created. ARM_* vars exported in this shell session."
echo "Run terraform init/plan/apply in same shell — no hardcode needed."
