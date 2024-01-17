
terraform {
  required_version = ">= 1.4.6"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "=1.11.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}
