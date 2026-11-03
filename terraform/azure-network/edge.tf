# ---------------------------------------------------------------
# Subred de borde + gateway virtual (NVA) + enrutamiento definido
# por el usuario (UDR). Reproduce en Azure las funciones del
# perímetro y del core del CD Principal con constructos cloud.
# ---------------------------------------------------------------

resource "azurerm_subnet" "edge" {
  name                 = "snet-edge"
  resource_group_name  = data.azurerm_resource_group.nexlog.name
  virtual_network_name = azurerm_virtual_network.cds_ext.name
  address_prefixes     = [var.subnet_edge_prefix]
}

resource "azurerm_network_security_group" "edge" {
  name                = "nsg-nexlog-edge"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.nexlog.name
  tags                = local.tags

  # Único servicio expuesto a Internet: el túnel cifrado, y solo
  # desde la IP pública del laboratorio.
  security_rule {
    name                       = "Allow-WireGuard-From-Lab"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "51820"
    source_address_prefix      = var.wg_allowed_source
    destination_address_prefix = var.nva_private_ip
  }

  # Tráfico de la subred de aplicaciones que el NVA enruta y traduce
  # (salida a Internet y respuestas hacia el CD Secundario).
  security_rule {
    name                       = "Allow-Apps-Via-NVA"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subnet_apps_prefix
    destination_address_prefix = "*"
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

resource "azurerm_subnet_network_security_group_association" "edge" {
  subnet_id                 = azurerm_subnet.edge.id
  network_security_group_id = azurerm_network_security_group.edge.id
}

# Toda la salida de snet-apps pasa por el NVA: hacia el CD Secundario
# (por el túnel) y hacia Internet (con NAT). Es el método de salida
# explícito que Azure recomienda para subredes privadas.
resource "azurerm_route_table" "apps" {
  name                          = "rt-nexlog-apps"
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.nexlog.name
  bgp_route_propagation_enabled = false
  tags                          = local.tags

  route {
    name                   = "to-cds-via-nva"
    address_prefix         = var.cds_lan_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  }

  route {
    name                   = "default-via-nva"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "apps" {
  subnet_id      = azurerm_subnet.apps.id
  route_table_id = azurerm_route_table.apps.id
}
