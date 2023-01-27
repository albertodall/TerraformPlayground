# *** FRONTEND ***

resource "azurerm_network_interface" "frontend1-nic" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-frontend-01-nic"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_windows_virtual_machine" "frontend1" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-frontend-01-vm"
  computer_name       = "${var.project_name}-fe-01"
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  size                = "Standard_DS1_v2"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.frontend1-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    name                 = "${var.region_short}-${var.project_name}-${var.environment_name}-frontend-01-osdsk"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.vnet-networklink
  ]

  tags = {
    environment = var.environment_name
  }
}

# *** DATABASE SERVER ***

resource "azurerm_network_interface" "dbserver1-nic" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-dbserver-01-nic"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.data-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_windows_virtual_machine" "dbserver1" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-dbserver-01-vm"
  computer_name       = "${var.project_name}-db-01"
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  size                = "Standard_DS1_v2"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.dbserver1-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    name                 = "${var.region_short}-${var.project_name}-${var.environment_name}-dbserver-01-osdsk"
    storage_account_type = "Standard_LRS"
  }

  # az vm image list --location westeurope  --publisher MicrosoftSQLServer  --all --output table
  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2022"
    sku       = "sqldev-gen2"
    version   = "latest"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.vnet-networklink
  ]

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_managed_disk" "dbserver1-data-disk" {
  name                 = "${var.region_short}-${var.project_name}-${var.environment_name}-dbserver-01-data-dsk"
  location             = azurerm_resource_group.resource-group.location
  resource_group_name  = azurerm_resource_group.resource-group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "dbserver1-data-disk-attach" {
  managed_disk_id    = azurerm_managed_disk.dbserver1-data-disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.dbserver1.id
  lun                = 10
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "dbserver1-log-disk" {
  name                 = "${var.region_short}-${var.project_name}-${var.environment_name}-dbserver-01-log-dsk"
  location             = azurerm_resource_group.resource-group.location
  resource_group_name  = azurerm_resource_group.resource-group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "dbserver1-log-disk-attach" {
  managed_disk_id    = azurerm_managed_disk.dbserver1-log-disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.dbserver1.id
  lun                = 11
  caching            = "None"
}

resource "azurerm_mssql_virtual_machine" "dbserver1_sql_config" {
  virtual_machine_id               = azurerm_windows_virtual_machine.dbserver1.id
  sql_license_type                 = "PAYG"
  sql_connectivity_port            = 1433
  sql_connectivity_update_username = var.sql_admin_username
  sql_connectivity_update_password = var.sql_admin_password
  r_services_enabled               = false

  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "OLTP"

    data_settings {
      default_file_path = "X:\\sqldata"
      luns              = [azurerm_virtual_machine_data_disk_attachment.dbserver1-data-disk-attach.lun]
    }

    log_settings {
      default_file_path = "Y:\\sqldata"
      luns              = [azurerm_virtual_machine_data_disk_attachment.dbserver1-log-disk-attach.lun]
    }

    temp_db_settings {
      default_file_path = "D:\\tempdb"
      luns              = []
    }
  }

  sql_instance {
    adhoc_workloads_optimization_enabled = true
    instant_file_initialization_enabled  = true
    max_dop                              = 1
  }
}