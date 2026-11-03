# APP-AZ-01: réplica de lectura del inventario WMS para contingencia.
# Sin IP pública: solo es alcanzable desde el CD Secundario por el túnel.

resource "azurerm_network_interface" "app" {
  name                = "nic-nexlog-app-az"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.apps.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.app_private_ip
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "vm-nexlog-app-az"
  computer_name         = "app-az-01"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.nexlog.name
  size                  = var.app_size
  zone                  = var.vm_zone
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.app.id]
  tags                  = local.tags

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.admin_ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.ubuntu.publisher
    offer     = local.ubuntu.offer
    sku       = local.ubuntu.sku
    version   = local.ubuntu.version
  }

  # Identidad administrada: la VM obtiene tokens de Entra ID sin secretos.
  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init/app.yaml.tftpl", {
    enable_replica  = var.enable_inventory_replica
    storage_account = var.storage_account_name
    container       = var.backup_container_name
  }))

  boot_diagnostics {}

  # La VM instala paquetes a través del NVA: debe existir antes.
  depends_on = [azurerm_linux_virtual_machine.gw]
}

# Mínimo privilegio: solo lectura y solo sobre el contenedor de respaldos.
resource "azurerm_role_assignment" "app_blob_reader" {
  count                = var.enable_inventory_replica ? 1 : 0
  scope                = "${data.azurerm_storage_account.backups[0].id}/blobServices/default/containers/${var.backup_container_name}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.app.identity[0].principal_id
}
