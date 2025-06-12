# Variables for Azure Infrastructure
# Defining variables allows for reuse and easier configuration changes

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "Southeast Asia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-k3s"
}

variable "admin_username" {
  description = "Username for the VM admin account"
  type        = string
  default     = "adminuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for VM authentication"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  description = "Size of the Azure VM"
  type        = string
  default     = "Standard_B1s"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "k3s_subnet_prefix" {
  description = "Address prefix for the K3s subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for the Gateway subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
} 