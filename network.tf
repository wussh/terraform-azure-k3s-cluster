# Network Security Group Block for K3s Subnet
# A network security group contains security rules that allow or deny
# inbound and outbound network traffic to Azure resources.
resource "azurerm_network_security_group" "k3s" {
  name                = "nsg-k3s"             # Name of the security group
  location            = azurerm_resource_group.k3s.location  # Uses the same location as the resource group
  resource_group_name = azurerm_resource_group.k3s.name     # Associates with the resource group
  
  # Allow SSH traffic
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow K3s supervisor and Kubernetes API Server (agents to server)
  security_rule {
    name                       = "allow-k8s-api"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow etcd (for HA clusters)
  security_rule {
    name                       = "allow-etcd"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow Flannel VXLAN
  security_rule {
    name                       = "allow-flannel-vxlan"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "8472"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow Kubelet metrics
  security_rule {
    name                       = "allow-kubelet-metrics"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow Flannel Wireguard IPv4
  security_rule {
    name                       = "allow-flannel-wireguard-ipv4"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "51820"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow Flannel Wireguard IPv6
  security_rule {
    name                       = "allow-flannel-wireguard-ipv6"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "51821"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow embedded distributed registry (Spegel)
  security_rule {
    name                       = "allow-spegel"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5001"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow embedded distributed registry (Spegel) on 6443
  security_rule {
    name                       = "allow-spegel-6443"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Allow HTTP traffic
  security_rule {
    name                       = "allow-http"
    priority                   = 210
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
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Istio HTTP traffic
  security_rule {
    name                       = "allow-istio-http"
    priority                   = 230
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Istio HTTPS traffic
  security_rule {
    name                       = "allow-istio-https"
    priority                   = 240
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
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
  
  # Allow SSH traffic
  security_rule {
    name                       = "allow-ssh"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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
    public_ip_address_id          = azurerm_public_ip.master.id
  }
}

# Public IP for Master VM
resource "azurerm_public_ip" "master" {
  name                = "pip-k3s-master"
  location            = azurerm_resource_group.k3s.location
  resource_group_name = azurerm_resource_group.k3s.name
  allocation_method   = "Static"
  sku                 = "Standard"
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

# Associate Master VM NIC with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "master" {
  network_interface_id    = azurerm_network_interface.master.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.k3s.id
} 

# Associate Worker VM NIC with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "worker" {
  network_interface_id    = azurerm_network_interface.worker.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.k3s.id
} 