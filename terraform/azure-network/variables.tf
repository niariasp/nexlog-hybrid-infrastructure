variable "resource_group_name" {
  description = "Resource Group existente, creado por el módulo terraform/azure (no se gestiona aquí)."
  type        = string
  default     = "rg-nexlog-capstone-dev"
}

variable "location" {
  description = "Región de la red Cloud. Brazil South está permitida por la suscripción y es la misma región del Storage."
  type        = string
  default     = "brazilsouth"
}

variable "vnet_address_space" {
  description = "Espacio de la VNet, según el diseño declarado en el Informe de Avance Fase 2."
  type        = string
  default     = "10.100.0.0/16"
}

variable "subnet_apps_prefix" {
  description = "Subred de aplicaciones/servicios de la extensión Cloud del CD Secundario."
  type        = string
  default     = "10.100.10.0/24"
}

variable "subnet_mgmt_prefix" {
  description = "Subred de gestión de la extensión Cloud."
  type        = string
  default     = "10.100.20.0/24"
}

variable "cds_lan_prefix" {
  description = "LAN del CD Secundario en GNS3, origen autorizado hacia los servicios Cloud."
  type        = string
  default     = "10.20.20.0/24"
}

# --- Extensión funcional (Fase A, 2026-11) ---

variable "subnet_edge_prefix" {
  description = "Subred de borde: aloja el gateway virtual (NVA) con IP pública, equivalente al perímetro del CD Principal."
  type        = string
  default     = "10.100.1.0/24"
}

variable "nva_private_ip" {
  description = "IP privada fija del gateway virtual GW-AZ-01 (siguiente salto de la tabla de rutas de snet-apps)."
  type        = string
  default     = "10.100.1.4"
}

variable "wg_allowed_source" {
  description = "Origen autorizado para WireGuard (UDP 51820). Usar la IP pública actual del laboratorio en formato x.x.x.x/32."
  type        = string
}
