# K3s Master VM
resource "azurerm_linux_virtual_machine" "master" {
  name                            = "vm-k3s-master"
  resource_group_name             = azurerm_resource_group.k3s.name
  location                        = azurerm_resource_group.k3s.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

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

  # Copy SSH private key to master VM so it can reach worker nodes
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

  # Set key permissions and register all workers in known_hosts and /etc/hosts
  provisioner "remote-exec" {
    inline = flatten([
      ["chmod 600 /home/${var.admin_username}/.ssh/id_rsa"],
      [for i in range(var.worker_count) :
        "echo '${azurerm_network_interface.worker[i].private_ip_address} ${azurerm_linux_virtual_machine.worker[i].name}' | sudo tee -a /etc/hosts"
      ],
      [for i in range(var.worker_count) :
        "ssh-keyscan -H ${azurerm_network_interface.worker[i].private_ip_address} >> /home/${var.admin_username}/.ssh/known_hosts"
      ],
    ])

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = tls_private_key.ssh.private_key_pem
      host        = azurerm_public_ip.master.ip_address
    }
  }

  tags = {
    environment = var.environment
    role        = "K3s-Master"
  }
}

# K3s Worker VMs
resource "azurerm_linux_virtual_machine" "worker" {
  count                           = var.worker_count
  name                            = "vm-k3s-worker-${count.index + 1}"
  resource_group_name             = azurerm_resource_group.k3s.name
  location                        = azurerm_resource_group.k3s.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.worker[count.index].id,
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
    environment = var.environment
    role        = "K3s-Worker"
  }
}