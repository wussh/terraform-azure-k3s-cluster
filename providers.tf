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
  name     = var.resource_group_name
  location = var.location
} 