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

variable "environment" {
  description = "Environment tag applied to all resources (e.g. Production, Staging, Development)"
  type        = string
  default     = "Production"
}

variable "admin_username" {
  description = "Username for the VM admin account"
  type        = string
  default     = "wush"
}

variable "vm_size" {
  description = "Size of the Azure VM"
  type        = string
  default     = "Standard_B2s"
}

variable "worker_count" {
  description = "Number of K3s worker VMs to provision"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 1
    error_message = "worker_count must be at least 1."
  }
}

variable "ssh_allowed_cidr" {
  description = "CIDR range allowed to reach the VMs on port 22. Restrict to your own IP in production."
  type        = string
  default     = "*"
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