resource "azurerm_resource_group" "resource-group" {
  name     = "${var.region_short}-${var.project_name}-${var.environment_name}-rg"
  location = "West Europe"

  tags = {
    environment = var.environment_name
  }
}