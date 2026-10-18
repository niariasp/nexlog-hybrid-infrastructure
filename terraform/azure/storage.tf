data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "wms" {
  name = "stnexlog${substr(md5(data.azurerm_client_config.current.subscription_id), 0, 8)}"

  resource_group_name = azurerm_resource_group.nexlog.name
  location            = "brazilsouth"

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    project     = "NexLog-Chile"
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_container" "wms_backups" {
  name                  = "wms-backups"
  storage_account_id    = azurerm_storage_account.wms.id
  container_access_type = "private"
}
