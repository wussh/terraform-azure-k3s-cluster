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
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Copy SSH private key to master VM for worker access
  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/${var.admin_username}/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = tls_private_key.ssh.private_key_pem
      host        = azurerm_public_ip.master.ip_address
    }
  }

  # Set permissions and add worker to known hosts
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.admin_username}/.ssh/id_rsa",
      "echo '${azurerm_network_interface.worker.private_ip_address} ${azurerm_linux_virtual_machine.worker.name}' | sudo tee -a /etc/hosts",
      "ssh-keyscan -H ${azurerm_network_interface.worker.private_ip_address} >> /home/${var.admin_username}/.ssh/known_hosts"
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = tls_private_key.ssh.private_key_pem
      host        = azurerm_public_ip.master.ip_address
    }
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
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    environment = "Production"
    role        = "K3s-Worker"
  }
} 