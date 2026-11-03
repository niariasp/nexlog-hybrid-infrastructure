# GW-AZ-01: gateway virtual (NVA). WireGuard hacia el CD Secundario,
# nftables deny-by-default y NAT de salida para snet-apps.

resource "azurerm_public_ip" "gw" {
  name                = "pip-nexlog-gw-az"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "gw" {
  name                  = "nic-nexlog-gw-az"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.nexlog.name
  ip_forwarding_enabled = true # necesario para que Azure entregue tráfico en tránsito al NVA
  tags                  = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.edge.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.nva_private_ip
    public_ip_address_id          = azurerm_public_ip.gw.id
  }
}

resource "azurerm_linux_virtual_machine" "gw" {
  name                  = "vm-nexlog-gw-az"
  computer_name         = "gw-az-01"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.nexlog.name
  size                  = var.gw_size
  zone                  = var.vm_zone
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.gw.id]
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

  # Solo datos públicos: la clave privada WireGuard se genera dentro de
  # la VM en el primer arranque y nunca pasa por el estado de Terraform.
  custom_data = base64encode(templatefile("${path.module}/cloud-init/gw.yaml.tftpl", {
    cds_wg_public_key  = var.cds_wg_public_key
    cds_lan_prefix     = var.cds_lan_prefix
    subnet_apps_prefix = var.subnet_apps_prefix
  }))

  boot_diagnostics {} # consola serie: permite leer la clave pública generada
}
