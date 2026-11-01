# Este módulo tiene su propio estado (terraform.tfstate en esta carpeta).
# El Resource Group y el Storage se leen como data sources: un
# "terraform destroy" aquí NO puede eliminar los recursos de terraform/azure.

data "azurerm_resource_group" "nexlog" {
  name = var.resource_group_name
}

locals {
  tags = {
    project     = "NexLog-Chile"
    environment = "dev"
    managed_by  = "terraform"
    component   = "cds-cloud-extension"
  }
}
