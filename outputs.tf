output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "dc01_private_ip" {
  value = var.dc01_private_ip
}

output "dc02_private_ip" {
  value = var.dc02_private_ip
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "bastion_enabled" {
  value = var.enable_bastion
}
