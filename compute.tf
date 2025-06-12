# K3s Master VM
resource "azurerm_linux_virtual_machine" "master" {
  name                = "vm-k3s-master"
  resource_group_name = azurerm_resource_group.k3s.name
  location            = azurerm_resource_group.k3s.location
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.master.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
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
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.worker.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
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