# Main Terraform configuration file
# This file serves as the entry point to the Terraform configuration
# The resources have been split into separate files for better organization:
# - providers.tf: Contains provider configuration and resource group
# - variables.tf: Contains all variable definitions
# - network.tf: Contains network-related resources (VNet, subnets, NSGs)
# - loadbalancer.tf: Contains load balancer and related resources
# - compute.tf: Contains VM-related resources
# - outputs.tf: Contains output definitions

# The empty main.tf file ensures that terraform knows this is a valid terraform directory
# All resources are defined in the other files

# Generate SSH key pair for VMs
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/k3s_ssh_key"
  file_permission = "0600"
}

# Save public key to local file
resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${path.module}/k3s_ssh_key.pub"
  file_permission = "0644"
}