# Terraform Block
# This block configures Terraform itself, specifying the required providers
# and their versions. This ensures consistent infrastructure deployments
# across different environments and team members.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  # Official Azure provider from HashiCorp
      version = "=4.1.0"             # Pinned to exact version for stability
    }
  }
}

# Azure Provider Block
# This block configures the Azure provider with authentication details
# and any provider-specific settings. The 'features' block is required
# even if empty.
provider "azurerm" {
  features {}  # Required empty block for provider configuration

  subscription_id = "bfa50e12-83e7-4b2e-964a-0af466ad693f"  # Identifies which Azure subscription to use
  tenant_id       = "5b6ecfc1-146f-4794-93b3-6f9c4650a642"  # Identifies which Azure AD tenant to use
}

# Resource Group Block
# A resource group is a logical container for Azure resources.
# All Azure resources must be deployed into a resource group.
resource "azurerm_resource_group" "k3s" {
  name     = "rg-k3s"        # Name of the resource group
  location = "Southeast Asia" # Geographic location where the resource group will be created
}

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
  address_space       = ["10.0.0.0/16"]                     # IP address range for the entire virtual network
}

# K3s Subnet
resource "azurerm_subnet" "k3s" {
  name                 = "subnet-k3s"
  resource_group_name  = azurerm_resource_group.k3s.name
  virtual_network_name = azurerm_virtual_network.k3s.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Gateway Subnet
resource "azurerm_subnet" "gateway" {
  name                 = "subnet-gateway"
  resource_group_name  = azurerm_resource_group.k3s.name
  virtual_network_name = azurerm_virtual_network.k3s.name
  address_prefixes     = ["10.0.2.0/24"]
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

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "pip-k3s-lb"
  location            = azurerm_resource_group.k3s.location
  resource_group_name = azurerm_resource_group.k3s.name
  allocation_method   = "Static"
  sku                 = "Standard"  # Required for Standard Load Balancer
}

# Azure Load Balancer
resource "azurerm_lb" "k3s" {
  name                = "lb-k3s"
  location            = azurerm_resource_group.k3s.location
  resource_group_name = azurerm_resource_group.k3s.name
  sku                 = "Standard"  # Standard SKU for production workloads

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Load Balancer Backend Pool
resource "azurerm_lb_backend_address_pool" "k3s" {
  loadbalancer_id = azurerm_lb.k3s.id
  name            = "istio-gateway-pool"
}

# Load Balancer HTTP Rule
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.k3s.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# Load Balancer HTTPS Rule
resource "azurerm_lb_rule" "https" {
  loadbalancer_id                = azurerm_lb.k3s.id
  name                           = "https"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
  probe_id                       = azurerm_lb_probe.https.id
}

# Load Balancer Health Probe for HTTP
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.k3s.id
  name            = "http-running-probe"
  port            = 80
}

# Load Balancer Health Probe for HTTPS
resource "azurerm_lb_probe" "https" {
  loadbalancer_id = azurerm_lb.k3s.id
  name            = "https-running-probe"
  port            = 443
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

# K3s Master VM
resource "azurerm_linux_virtual_machine" "master" {
  name                = "vm-k3s-master"
  resource_group_name = azurerm_resource_group.k3s.name
  location            = azurerm_resource_group.k3s.location
  size                = "Standard_B1s"  # Lightweight VM size as specified
  admin_username      = "adminuser"
  
  network_interface_ids = [
    azurerm_network_interface.master.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Replace with your SSH public key path
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "Production"
    role        = "K3s-Master"
  }
}

# K3s Worker VM
resource "azurerm_linux_virtual_machine" "worker" {
  name                = "vm-k3s-worker"
  resource_group_name = azurerm_resource_group.k3s.name
  location            = azurerm_resource_group.k3s.location
  size                = "Standard_B1s"  # Lightweight VM size as specified
  admin_username      = "adminuser"
  
  network_interface_ids = [
    azurerm_network_interface.worker.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Replace with your SSH public key path
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "Production"
    role        = "K3s-Worker"
  }
}