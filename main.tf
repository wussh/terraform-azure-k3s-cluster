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