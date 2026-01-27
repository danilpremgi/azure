# NICs
resource "azurerm_network_interface" "dc01" {
  name                = "nic-${local.dc01_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.dc.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dc01_private_ip
  }

  dns_servers = local.dns_servers

  accelerated_networking_enabled = true
  tags                           = var.tags
}

resource "azurerm_network_interface" "dc02" {
  name                = "nic-${local.dc02_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.dc.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dc02_private_ip
  }

  dns_servers = local.dns_servers

  accelerated_networking_enabled = true
  tags                           = var.tags
}

# Data disks for AD database/logs/sysvol (host caching must be None)
resource "azurerm_managed_disk" "dc01_data" {
  name                 = "disk-${local.dc01_name}-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
  zone                 = each.value.zone
  tags                 = var.tags
}

resource "azurerm_managed_disk" "dc02_data" {
  name                 = "disk-${local.dc02_name}-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
  zone                 = each.value.zone
  tags                 = var.tags
}

resource "azurerm_windows_virtual_machine" "dc01" {
  name                = local.dc01_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size           = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.dc01.id]

  zone = try(var.vm_zones[0], null)

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  patch_mode                = "AutomaticByPlatform"
  provision_vm_agent        = true
  automatic_updates_enabled = true

  boot_diagnostics {
    storage_account_uri = null
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "dc02" {
  name                = local.dc02_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size           = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.dc02.id]

  zone = try(var.vm_zones[1], null)

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  patch_mode                = "AutomaticByPlatform"
  provision_vm_agent        = true
  automatic_updates_enabled = true

  boot_diagnostics {
    storage_account_uri = null
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "dc01" {
  managed_disk_id    = azurerm_managed_disk.dc01_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.dc01.id
  lun                = 0
  caching            = "None"
}

resource "azurerm_virtual_machine_data_disk_attachment" "dc02" {
  managed_disk_id    = azurerm_managed_disk.dc02_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.dc02.id
  lun                = 0
  caching            = "None"
}
