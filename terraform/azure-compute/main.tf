# Módulo de cómputo de la extensión Cloud del CD Secundario.
# Estado propio: un "destroy" aquí no afecta la red (azure-network) ni el
# Storage (azure). La red y el Storage se leen como data sources.

data "azurerm_resource_group" "nexlog" {
  name = var.resource_group_name
}

data "azurerm_subnet" "edge" {
  name                 = "snet-edge"
  virtual_network_name = var.vnet_name
  resource_group_name  = data.azurerm_resource_group.nexlog.name
}

data "azurerm_subnet" "apps" {
  name                 = "snet-apps"
  virtual_network_name = var.vnet_name
  resource_group_name  = data.azurerm_resource_group.nexlog.name
}

data "azurerm_storage_account" "backups" {
  count               = var.enable_inventory_replica ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.nexlog.name
}

locals {
  tags = {
    project     = "NexLog-Chile"
    environment = "dev"
    managed_by  = "terraform"
    component   = "cds-cloud-extension"
  }

  ubuntu = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
