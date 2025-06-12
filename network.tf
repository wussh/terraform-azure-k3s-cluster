# Network Security Group Block for K3s Subnet
# A network security group contains security rules that allow or deny
# inbound and outbound network traffic to Azure resources.
resource "azurerm_network_security_group" "k3s" {
  name                = "nsg-k3s"             # Name of the security group
  location            = azurerm_resource_group.k3s.location  # Uses the same location as the resource group
  resource_group_name = azurerm_resource_group.k3s.name     # Associates with the resource group
}

# Network Security Group Block for Gateway Subnet
resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-gateway"             # Name of the security group
  location            = azurerm_resource_group.k3s.location  # Uses the same location as the resource group
  resource_group_name = azurerm_resource_group.k3s.name     # Associates with the resource group
  
  # Allow HTTP traffic
  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow HTTPS traffic
  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Virtual Network Block
# A virtual network is the fundamental building block for your private network in Azure.
# It enables Azure resources to securely communicate with each other, the internet, and on-premises networks.
resource "azurerm_virtual_network" "k3s" {
  name                = "vnet-k3s"                    # Name of the virtual network
  location            = azurerm_resource_group.k3s.location  # Uses the same location as the resource group
  resource_group_name = azurerm_resource_group.k3s.name     # Associates with the resource group
  address_space       = var.vnet_address_space
}

# K3s Subnet
resource "azurerm_subnet" "k3s" {
  name                 = "subnet-k3s"
  resource_group_name  = azurerm_resource_group.k3s.name
  virtual_network_name = azurerm_virtual_network.k3s.name
  address_prefixes     = var.k3s_subnet_prefix
}

# Gateway Subnet
resource "azurerm_subnet" "gateway" {
  name                 = "subnet-gateway"
  resource_group_name  = azurerm_resource_group.k3s.name
  virtual_network_name = azurerm_virtual_network.k3s.name
  address_prefixes     = var.gateway_subnet_prefix
}

# Associate NSG with K3s Subnet
resource "azurerm_subnet_network_security_group_association" "k3s" {
  subnet_id                 = azurerm_subnet.k3s.id
  network_security_group_id = azurerm_network_security_group.k3s.id
}

# Associate NSG with Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Network Interface for K3s Master VM
resource "azurerm_network_interface" "master" {
  name                = "nic-k3s-master"
  location            = azurerm_resource_group.k3s.location
  resource_group_name = azurerm_resource_group.k3s.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k3s.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for K3s Worker VM
resource "azurerm_network_interface" "worker" {
  name                = "nic-k3s-worker"
  location            = azurerm_resource_group.k3s.location
  resource_group_name = azurerm_resource_group.k3s.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k3s.id
    private_ip_address_allocation = "Dynamic"
  }
} 