locals {
  dsrm_password_effective = length(trim(var.dsrm_password)) > 0 ? var.dsrm_password : var.admin_password

  vnet_name        = "vnet-identity"
  dc_subnet_name   = "snet-domaincontrollers"
  bastion_subnet   = "AzureBastionSubnet"

  dc01_name = "dc01"
  dc02_name = "dc02"

  # Common DNS list for NIC and VNet
  dns_servers = [var.dc01_private_ip, var.dc02_private_ip]
}
