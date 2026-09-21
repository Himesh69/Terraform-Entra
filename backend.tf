terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate2298121177"
    container_name       = "tfstate"
    key                  = "project/terraform.tfstate"
    tenant_id            = "ff93a2fa-ff2c-40fd-b26a-36c50ea51890"
    subscription_id      = "c1210efc-75aa-4ffb-891a-e1c38f9f32ff"
  }
}