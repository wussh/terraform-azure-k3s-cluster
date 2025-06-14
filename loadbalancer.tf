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

# Load Balancer SSH Rule for Master VM
resource "azurerm_lb_rule" "ssh_master" {
  loadbalancer_id                = azurerm_lb.k3s.id
  name                           = "ssh-master"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
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

# Load Balancer Istio HTTP Rule
resource "azurerm_lb_rule" "istio_http" {
  loadbalancer_id                = azurerm_lb.k3s.id
  name                           = "istio-http"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
  probe_id                       = azurerm_lb_probe.istio_http.id
}

# Load Balancer Istio HTTPS Rule
resource "azurerm_lb_rule" "istio_https" {
  loadbalancer_id                = azurerm_lb.k3s.id
  name                           = "istio-https"
  protocol                       = "Tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.k3s.id]
  probe_id                       = azurerm_lb_probe.istio_https.id
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

# Load Balancer Health Probe for Istio HTTP
resource "azurerm_lb_probe" "istio_http" {
  loadbalancer_id = azurerm_lb.k3s.id
  name            = "istio-http-running-probe"
  port            = 8080
}

# Load Balancer Health Probe for Istio HTTPS
resource "azurerm_lb_probe" "istio_https" {
  loadbalancer_id = azurerm_lb.k3s.id
  name            = "istio-https-running-probe"
  port            = 8443
} 