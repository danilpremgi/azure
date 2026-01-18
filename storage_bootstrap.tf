# Storage account used to host bootstrap scripts (required for Custom Script Extension fileUris)
resource "random_string" "sa" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "bootstrap" {
  name                     = "stboot${random_string.sa.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  min_tls_version                = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.bootstrap.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "dc01_script" {
  name                   = "promote-dc01.ps1"
  storage_account_name   = azurerm_storage_account.bootstrap.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/promote-dc01.ps1"
}

resource "azurerm_storage_blob" "dc02_script" {
  name                   = "promote-dc02.ps1"
  storage_account_name   = azurerm_storage_account.bootstrap.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/promote-dc02.ps1"
}

# SAS token for script download
# Short lifetime is fine; extension downloads scripts during provisioning
# NOTE: Token is present in state; treat state as sensitive.
data "azurerm_storage_account_sas" "scripts" {
  connection_string = azurerm_storage_account.bootstrap.primary_connection_string

  https_only = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2025-01-01T00:00:00Z"
  expiry = "2030-01-01T00:00:00Z"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

locals {
  dc01_script_uri = "https://${azurerm_storage_account.bootstrap.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.dc01_script.name}${data.azurerm_storage_account_sas.scripts.sas}"
  dc02_script_uri = "https://${azurerm_storage_account.bootstrap.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.dc02_script.name}${data.azurerm_storage_account_sas.scripts.sas}"
}
