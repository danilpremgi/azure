# -----------------------------
# Required
# -----------------------------
subscription_id = "00000000-0000-0000-0000-000000000000"

resource_group_name = "rg-identity-dc"
location            = "uksouth"

# Domain / AD
ad_domain_name   = "corp.example.com"
ad_netbios_name  = "CORP"

# VM admin (local admin; becomes initial domain admin when you create a new forest)
admin_username = "azureadmin"
admin_password = "ChangeMe-Use-A-Strong-Password!"

# Directory Services Restore Mode (DSRM) password
# You may set equal to admin_password if desired
# dsrm_password = "ChangeMe-Use-A-Strong-Password!"

# -----------------------------
# Optional
# -----------------------------
# Enable Bastion to manage DCs securely without public IPs
enable_bastion = true

# Enable automatic domain promotion
# Recommended: start false, confirm infra OK, then set true
enable_domain_promotion = false

# IP plan
vnet_address_space     = ["10.10.0.0/16"]
dc_subnet_prefix       = "10.10.10.0/24"
bastion_subnet_prefix  = "10.10.20.0/26"   # must be named AzureBastionSubnet

# DC static IPs (must be inside dc_subnet_prefix)
dc01_private_ip = "10.10.10.4"
dc02_private_ip = "10.10.10.5"

# VM settings
vm_size  = "Standard_D2s_v5"
vm_zones = ["1", "2"]

# Log Analytics
law_retention_days = 30
