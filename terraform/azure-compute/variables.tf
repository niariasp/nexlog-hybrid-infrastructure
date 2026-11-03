variable "resource_group_name" {
  description = "Resource Group existente (gestionado por terraform/azure)."
  type        = string
  default     = "rg-nexlog-capstone-dev"
}

variable "location" {
  description = "Misma región de la VNet y del Storage."
  type        = string
  default     = "brazilsouth"
}

variable "vnet_name" {
  description = "VNet creada por terraform/azure-network."
  type        = string
  default     = "vnet-nexlog-cds-ext"
}

variable "admin_username" {
  type    = string
  default = "nexlogadmin"
}

variable "admin_ssh_public_key_path" {
  description = "Ruta a la clave PÚBLICA SSH del administrador (nunca la privada)."
  type        = string
}

variable "cds_wg_public_key" {
  description = "Clave PÚBLICA WireGuard de GW-CDS-01 para la interfaz wg1."
  type        = string
}

# Ambos tamaños están incluidos en las 750 h/mes gratuitas de Azure for Students.
variable "gw_size" {
  type    = string
  default = "Standard_B1s" # B2ats v2 sin capacidad en brazilsouth (SkuNotAvailable, 2026-11-03)
}

variable "app_size" {
  type    = string
  default = "Standard_B1s"
}

variable "nva_private_ip" {
  type    = string
  default = "10.100.1.4"
}

variable "app_private_ip" {
  type    = string
  default = "10.100.10.4"
}

variable "cds_lan_prefix" {
  type    = string
  default = "10.20.20.0/24"
}

variable "subnet_apps_prefix" {
  type    = string
  default = "10.100.10.0/24"
}

# Fase 3: réplica de lectura del inventario desde Blob con Managed Identity.
variable "enable_inventory_replica" {
  type    = bool
  default = true
}

variable "storage_account_name" {
  type    = string
  default = "stnexlog91da1dd1"
}

variable "backup_container_name" {
  type    = string
  default = "wms-backups"
}

variable "vm_zone" {
  description = "Zona de disponibilidad (capacidad B-series restringida a nivel regional, 2026-11-03)."
  type        = string
  default     = null
}
