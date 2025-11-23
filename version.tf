terraform {
  required_version = ">= 1.13.5"
  backend "azurerm" {
    # leave this block here because otherwise self-hosted agents
    # will create their own local backend with local state file. This is not what we want.
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.54.0"
    }
  }
}