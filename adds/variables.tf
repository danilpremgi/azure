variable "subscription_id" {
  type        = string
  description = "Azure subscription id"
  default     = "1715a23c-998d-43ca-a609-4fddd118034b"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-dc"
}

variable "location" {
  type        = string
  description = "Azure region (e.g. uksouth)"
  default     = "uksouth"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    environment = "prod"
    workload    = "identity"
  }
}

# Networking
variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address spaces"
  default     = ["10.10.0.0/16"]
}

variable "dc_subnet_prefix" {
  type        = string
  description = "Subnet prefix for domain controllers"
  default     = "10.10.10.0/24"
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "Subnet prefix for Azure Bastion (AzureBastionSubnet)"
  default     = "10.10.20.0/26"
}

variable "dc01_private_ip" {
  type        = string
  description = "Static private IP for DC01"
  default     = "10.10.10.4"
}

variable "dc02_private_ip" {
  type        = string
  description = "Static private IP for DC02"
  default     = "10.10.10.5"
}

# VM settings
variable "vm_size" {
  type        = string
  description = "VM size"
  default     = "Standard_D2s_v5"
}

variable "vm_zones" {
  type        = list(string)
  description = "Availability zones to use for DC01 and DC02 (e.g. [\"1\",\"2\"])"
  default     = ["1", "2"]
}

variable "admin_username" {
  type        = string
  description = "Local admin username"
  default     = "azureadmin"
}

variable "admin_password" {
  type        = string
  description = "Local admin password (sensitive)"
  sensitive   = true
  default     = "MyP@ssw0rd1234!"
}

variable "dsrm_password" {
  type        = string
  description = "Directory Services Restore Mode password (sensitive). If unset, defaults to admin_password."
  default     = null
  nullable    = true
  sensitive   = true
}

# AD / Domain
variable "ad_domain_name" {
  type        = string
  description = "AD DS domain FQDN (e.g. corp.example.com)"
  default     = "corp.premgi.net"
}

variable "ad_netbios_name" {
  type        = string
  description = "AD DS NetBIOS name (e.g. CORP)"
  default     = "CORP"
}

# Bastion
variable "enable_bastion" {
  type        = bool
  description = "Deploy Azure Bastion"
  default     = true
}

# Monitoring
variable "law_retention_days" {
  type        = number
  description = "Log Analytics retention"
  default     = 30
}

# Automation
variable "enable_domain_promotion" {
  type        = bool
  description = "If true, runs scripts to promote DC01 to new forest and DC02 as additional DC"
  default     = false
}
