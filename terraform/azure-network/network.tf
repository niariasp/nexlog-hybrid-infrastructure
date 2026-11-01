# ---------------------------------------------------------------
# Red Cloud complementaria del CD Secundario (extensión, no reemplazo)
# ---------------------------------------------------------------

resource "azurerm_virtual_network" "cds_ext" {
  name                = "vnet-nexlog-cds-ext"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  address_space       = [var.vnet_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "apps" {
  name                 = "snet-apps"
  resource_group_name  = data.azurerm_resource_group.nexlog.name
  virtual_network_name = azurerm_virtual_network.cds_ext.name
  address_prefixes     = [var.subnet_apps_prefix]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "snet-mgmt"
  resource_group_name  = data.azurerm_resource_group.nexlog.name
  virtual_network_name = azurerm_virtual_network.cds_ext.name
  address_prefixes     = [var.subnet_mgmt_prefix]
}

# ---------------------------------------------------------------
# NSG de aplicaciones: mínimo privilegio + denegación explícita.
# La regla 4000 anula la regla por defecto AllowVnetInBound (65000),
# por lo que incluso el tráfico interno de la VNet debe estar permitido.
# ---------------------------------------------------------------

resource "azurerm_network_security_group" "apps" {
  name                = "nsg-nexlog-apps"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-CDS-to-Apps-HTTP-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = var.cds_lan_prefix
    destination_address_prefix = var.subnet_apps_prefix
  }

  security_rule {
    name                       = "Allow-Mgmt-to-Apps-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_mgmt_prefix
    destination_address_prefix = var.subnet_apps_prefix
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------------------------------------------------------------
# NSG de gestión: cerrado por defecto. El acceso administrativo se
# habilitará con una regla específica solo cuando exista una VM.
# ---------------------------------------------------------------

resource "azurerm_network_security_group" "mgmt" {
  name                = "nsg-nexlog-mgmt"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  tags                = local.tags

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "apps" {
  subnet_id                 = azurerm_subnet.apps.id
  network_security_group_id = azurerm_network_security_group.apps.id
}

resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}
