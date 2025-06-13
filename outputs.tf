# Outputs for Azure Infrastructure
# These outputs provide useful information after the infrastructure is deployed

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.k3s.name
}

output "master_vm_public_ip" {
  description = "The public IP address of the K3s master VM"
  value       = azurerm_public_ip.master.ip_address
}

output "master_vm_private_ip" {
  description = "The private IP address of the K3s master VM"
  value       = azurerm_network_interface.master.private_ip_address
}

output "worker_vm_private_ip" {
  description = "The private IP address of the K3s worker VM"
  value       = azurerm_network_interface.worker.private_ip_address
}

output "load_balancer_public_ip" {
  description = "The public IP address of the load balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.k3s.name
}

output "k3s_subnet_id" {
  description = "The ID of the K3s subnet"
  value       = azurerm_subnet.k3s.id
}

output "gateway_subnet_id" {
  description = "The ID of the gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_to_master_cmd" {
  description = "Command to SSH into the master VM"
  value       = "ssh -i ${local_file.private_key.filename} ${var.admin_username}@${azurerm_public_ip.master.ip_address}"
}

output "ssh_to_worker_from_master_cmd" {
  description = "Command to SSH from master VM to worker VM"
  value       = "ssh ${var.admin_username}@${azurerm_network_interface.worker.private_ip_address}"
} 