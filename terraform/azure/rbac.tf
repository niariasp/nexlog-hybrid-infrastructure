resource "azurerm_role_assignment" "wms_backup_operator" {
  scope                = azurerm_storage_container.wms_backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "wms_backup_service" {
  scope                = azurerm_storage_container.wms_backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "b7f6c079-1d2c-48aa-bd64-bffacf191ed5"
}
