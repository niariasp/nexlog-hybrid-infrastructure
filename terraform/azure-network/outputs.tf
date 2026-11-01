output "vnet_name" {
  value = azurerm_virtual_network.cds_ext.name
}

output "vnet_address_space" {
  value = azurerm_virtual_network.cds_ext.address_space
}

output "subnets" {
  value = {
    apps = azurerm_subnet.apps.address_prefixes[0]
    mgmt = azurerm_subnet.mgmt.address_prefixes[0]
  }
}

output "nsgs" {
  value = {
    apps = azurerm_network_security_group.apps.name
    mgmt = azurerm_network_security_group.mgmt.name
  }
}
