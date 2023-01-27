# *** PRIVATE DNS ZONE ***

resource "azurerm_private_dns_zone" "private-domain" {
  name                = var.private_domain_name
  resource_group_name = azurerm_resource_group.resource-group.name

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet-networklink" {
  name                  = "${var.region_short}-${var.project_name}-${var.environment_name}-pdnsv"
  resource_group_name   = azurerm_resource_group.resource-group.name
  private_dns_zone_name = azurerm_private_dns_zone.private-domain.name
  virtual_network_id    = azurerm_virtual_network.virtual-network.id
  registration_enabled  = true
}

# *** NSGs ***

resource "azurerm_network_security_group" "frontend-nsg" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-frontend-nsg"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "AllowBastionHostInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = azurerm_subnet.bastion-subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend-nsg-to-subnet" {
  subnet_id                 = azurerm_subnet.frontend-subnet.id
  network_security_group_id = azurerm_network_security_group.frontend-nsg.id
}

resource "azurerm_network_security_group" "data-nsg" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-data-nsg"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "AllowBastionHostInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = azurerm_subnet.bastion-subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_subnet_network_security_group_association" "data-nsg-to-subnet" {
  subnet_id                 = azurerm_subnet.data-subnet.id
  network_security_group_id = azurerm_network_security_group.data-nsg.id
}

resource "azurerm_network_security_group" "bastion-nsg" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-bastion-nsg"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBastionHostCommunicationInbound"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowBastionHostCommunicationOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowGetSessionInformation"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion-nsg-to-subnet" {
  subnet_id                 = azurerm_subnet.bastion-subnet.id
  network_security_group_id = azurerm_network_security_group.bastion-nsg.id
}

# *** BASTION ***

resource "azurerm_public_ip" "bastion-public-ip" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-bastion-pip"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-bastion-bash"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-public-ip.id
  }

  tags = {
    environment = var.environment_name
  }
}

# *** NAT Gateway ***

resource "azurerm_public_ip" "natgateway-public-ip" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-natgateway-pip"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_nat_gateway" "natgateway" {
  name                    = "${var.region_short}-${var.project_name}-${var.environment_name}-natgateway-ng"
  location                = azurerm_resource_group.resource-group.location
  resource_group_name     = azurerm_resource_group.resource-group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 5

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.natgateway.id
  public_ip_address_id = azurerm_public_ip.natgateway-public-ip.id
}

resource "azurerm_subnet_nat_gateway_association" "frontend-subnet-ng" {
  subnet_id      = azurerm_subnet.frontend-subnet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
}

resource "azurerm_subnet_nat_gateway_association" "backend-subnet-ng" {
  subnet_id      = azurerm_subnet.backend-subnet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
}

resource "azurerm_subnet_nat_gateway_association" "data-subnet-ng" {
  subnet_id      = azurerm_subnet.data-subnet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
}

# *** FIREWALL ***

resource "azurerm_public_ip" "firewall-public-ip" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-firewall-pip"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.region_short}-${var.project_name}-${var.environment_name}-firewall-afw"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = azurerm_subnet.firewall-subnet.id
    public_ip_address_id = azurerm_public_ip.firewall-public-ip.id
  }

  tags = {
    environment = var.environment_name
  }
}

resource "azurerm_firewall_nat_rule_collection" "frontend-inbound" {
  name                = "frontend-inbound-rules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.resource-group.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "frontend-rdp-in"

    source_addresses = ["*"]

    destination_ports     = ["33891"]
    destination_addresses = [azurerm_public_ip.firewall-public-ip.ip_address]

    translated_port    = 3389
    translated_address = azurerm_network_interface.frontend1-nic.private_ip_address

    protocols = ["TCP"]
  }

  rule {
    name = "frontend-http-in"

    source_addresses = ["*"]

    destination_ports     = ["80"]
    destination_addresses = [azurerm_public_ip.firewall-public-ip.ip_address]

    translated_port    = 80
    translated_address = azurerm_network_interface.frontend1-nic.private_ip_address

    protocols = ["TCP"]
  }

  rule {
    name = "frontend-https-in"

    source_addresses = ["*"]

    destination_ports     = ["443"]
    destination_addresses = [azurerm_public_ip.firewall-public-ip.ip_address]

    translated_port    = 443
    translated_address = azurerm_network_interface.frontend1-nic.private_ip_address

    protocols = ["TCP"]
  }
}
