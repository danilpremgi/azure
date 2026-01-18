# Azure: 2x Domain Controllers (AD DS) – Terraform (Ready to Deploy)

This Terraform project deploys **two Windows Server Domain Controller VMs** in Azure following common best practices:

- Dedicated VNet + **DC subnet**
- **Two DC VMs across Availability Zones** (where supported)
- **No public IPs** on the DCs
- Optional **Azure Bastion** for secure management access
- Separate **data disk** per DC for **NTDS DB / logs / SYSVOL**
- **Azure Monitor Agent (AMA)** + **Log Analytics Workspace** + **Data Collection Rule (DCR)** for DC monitoring
- Optional automated **domain creation + 2nd DC promotion** (toggle via variable)

> ⚠️ If you enable automatic domain promotion, expect reboots and allow time for DC01 to finish before DC02 promotes.

---

## Prerequisites

- Terraform >= 1.6
- AzureRM provider >= 4.x
- Logged into Azure (`az login`) or using a service principal

---

## Quick start

1) Copy `terraform.tfvars.example` to `terraform.tfvars` and edit values.

2) Init + deploy:

```bash
terraform init
terraform plan
terraform apply
```

---

## Recommended values

- **location**: `uksouth` (or your region)
- **enable_bastion**: `true` (so you can manage DCs without opening RDP)
- **enable_domain_promotion**: `false` initially; switch to `true` when you're ready

---

## Notes / Operations

### Monitoring
This creates:
- Log Analytics Workspace
- Azure Monitor Agent extension on DC01/DC02
- Data Collection Rule collecting:
  - System/Application/Directory Service/DNS Server/DFSR event logs
  - DC-relevant performance counters

### Domain promotion (optional)
When enabled, it will:
- Initialize & format the DC data disk as **F:**
- Install AD DS and DNS
- Promote DC01 to a **new forest** (Database/Logs/Sysvol on F:)
- Join DC02 to the domain and promote it as **additional DC**

---

## Clean up

```bash
terraform destroy
```
