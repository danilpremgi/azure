terraform {

  cloud {
    organization = "danilpremgi"

    workspaces {
      name = "azure"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
}
    time = {
      source  = "hashicorp/time"
    }
  }
}
