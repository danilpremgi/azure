# Optional: automatic domain creation + DC promotion using Custom Script Extension
# This relies on script blobs uploaded to the bootstrap storage account.

resource "time_sleep" "wait_dc01_ready" {
  count = var.enable_domain_promotion ? 1 : 0

  depends_on = [
    azurerm_windows_virtual_machine.dc01,
    azurerm_virtual_machine_data_disk_attachment.dc01,
    azurerm_storage_blob.dc01_script
  ]

  create_duration = "2m"
}

resource "azurerm_virtual_machine_extension" "promote_dc01" {
  count = var.enable_domain_promotion ? 1 : 0

  name               = "promote-dc01"
  virtual_machine_id = azurerm_windows_virtual_machine.dc01.id

  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [local.dc01_script_uri]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -File promote-dc01.ps1 -DomainName '${var.ad_domain_name}' -Netbios '${var.ad_netbios_name}' -SafeModePass '${local.dsrm_password_effective}'"
  })

  depends_on = [
    time_sleep.wait_dc01_ready
  ]
}

# Give DC01 time to reboot, finish AD DS promotion and start DNS
resource "time_sleep" "wait_after_dc01_promo" {
  count = var.enable_domain_promotion ? 1 : 0

  depends_on = [
    azurerm_virtual_machine_extension.promote_dc01
  ]

  # Tune as required for your environment
  create_duration = "20m"
}

resource "azurerm_virtual_machine_extension" "promote_dc02" {
  count = var.enable_domain_promotion ? 1 : 0

  name               = "promote-dc02"
  virtual_machine_id = azurerm_windows_virtual_machine.dc02.id

  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    fileUris = [local.dc02_script_uri]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -File promote-dc02.ps1 -DomainName '${var.ad_domain_name}' -Netbios '${var.ad_netbios_name}' -DomainAdminUser '${var.ad_netbios_name}\\Administrator' -DomainAdminPass '${var.admin_password}' -SafeModePass '${local.dsrm_password_effective}'"
  })

  depends_on = [
    time_sleep.wait_after_dc01_promo,
    azurerm_windows_virtual_machine.dc02,
    azurerm_virtual_machine_data_disk_attachment.dc02
  ]
}
