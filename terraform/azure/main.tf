resource "azurerm_resource_group" "nexlog" {
  name     = "rg-nexlog-capstone-dev"
  location = "eastus2"

  tags = {
    project     = "NexLog-Chile"
    environment = "dev"
    managed_by  = "terraform"
  }
}
