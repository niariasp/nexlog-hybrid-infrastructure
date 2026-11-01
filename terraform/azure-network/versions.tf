terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID.
# Los providers Microsoft.Network y Microsoft.Compute ya están registrados
# (verificado el 2026-11-01), por lo que se desactiva el registro automático.
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
