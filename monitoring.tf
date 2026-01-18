############################################
# Log Analytics Workspace
############################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-dc-monitoring"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku               = "PerGB2018"
  retention_in_days = var.law_retention_days

  tags = var.tags
}

############################################
# Azure Monitor Agent (AMA) VM extension
############################################
resource "azurerm_virtual_machine_extension" "ama_dc01" {
  name                       = "ama"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc01.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "ama_dc02" {
  name                       = "ama"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc02.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
}

############################################
# Data Collection Rule (Events + Perf)
############################################
resource "azurerm_monitor_data_collection_rule" "dcr_dcs" {
  name                = "dcr-domain-controllers"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  destinations {
    log_analytics {
      name                  = "la-destination"
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
    }
  }

  data_flow {
    streams       = ["Microsoft-Event"]
    destinations  = ["la-destination"]
    output_stream = "Microsoft-Event"
  }

  data_flow {
    streams       = ["Microsoft-Perf"]
    destinations  = ["la-destination"]
    output_stream = "Microsoft-Perf"
  }

  data_sources {
    windows_event_log {
      name    = "dc-event-logs"
      streams = ["Microsoft-Event"]

      x_path_queries = [
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Directory Service!*[System[(Level=1 or Level=2 or Level=3)]]",
        "DNS Server!*[System[(Level=1 or Level=2 or Level=3)]]",
        "DFS Replication!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }

    performance_counter {
      name                          = "dc-perf"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60

      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
        "\\Network Interface(*)\\Bytes Total/sec",
        "\\NTDS\\DRA Inbound Bytes Total/sec",
        "\\NTDS\\DRA Outbound Bytes Total/sec",
        "\\NTDS\\DS Threads in Use",
        "\\NTDS\\Database Cache % Hit",
        "\\DNS\\Total Query Received/sec",
        "\\DNS\\Total Response Sent/sec"
      ]
    }
  }

  depends_on = [
    azurerm_virtual_machine_extension.ama_dc01,
    azurerm_virtual_machine_extension.ama_dc02
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dc01" {
  name                    = "dcr-assoc-dc01"
  target_resource_id      = azurerm_windows_virtual_machine.dc01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_dcs.id
}

resource "azurerm_monitor_data_collection_rule_association" "dc02" {
  name                    = "dcr-assoc-dc02"
  target_resource_id      = azurerm_windows_virtual_machine.dc02.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_dcs.id
}
