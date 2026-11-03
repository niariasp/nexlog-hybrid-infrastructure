output "gw_public_ip" {
  description = "Endpoint WireGuard para GW-CDS-01 (puerto 51820)."
  value       = azurerm_public_ip.gw.ip_address
}

output "gw_private_ip" {
  value = azurerm_network_interface.gw.private_ip_address
}

output "app_private_ip" {
  value = azurerm_network_interface.app.private_ip_address
}

output "app_identity_principal_id" {
  value = azurerm_linux_virtual_machine.app.identity[0].principal_id
}

output "get_gw_wg_public_key" {
  description = "Lee la clave pública WireGuard de GW-AZ-01 por el plano de control (Run Command), sin SSH."
  value       = "az vm run-command invoke -g ${var.resource_group_name} -n ${azurerm_linux_virtual_machine.gw.name} --command-id RunShellScript --scripts \"cat /etc/wireguard/public.key\" --query value[0].message -o tsv"
}
