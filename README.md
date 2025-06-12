# Azure K3s Terraform Configuration

This project contains Terraform configuration to provision a Kubernetes (K3s) cluster on Azure. The infrastructure includes networking, load balancer, and compute resources to run a lightweight Kubernetes environment.

## Project Structure

The Terraform configuration is organized into multiple files for better maintainability:

- `main.tf` - The entry point for the Terraform configuration
- `providers.tf` - Provider configuration and resource group definition
- `variables.tf` - Variable definitions with default values
- `network.tf` - Network resources (VNet, subnets, NSGs, NICs)
- `loadbalancer.tf` - Load balancer and related resources
- `compute.tf` - Virtual machine resources
- `outputs.tf` - Output definitions

## Prerequisites

- Terraform v1.0.0 or newer
- Azure CLI installed and configured
- SSH keypair for VM authentication

## Usage

1. Initialize the Terraform working directory:

```bash
terraform init
```

2. Review the execution plan:

```bash
terraform plan
```

3. Apply the changes:

```bash
terraform apply
```

4. When you're done with the infrastructure, you can destroy it:

```bash
terraform destroy
```

## Customization

You can customize the deployment by modifying the variables in `variables.tf` or by providing override values:

```bash
terraform apply -var="location=eastus" -var="vm_size=Standard_B2s"
```

Alternatively, create a `terraform.tfvars` file:

```hcl
location = "eastus"
vm_size = "Standard_B2s"
admin_username = "myadmin"
```

## Resources Created

- Resource Group
- Virtual Network with two subnets (K3s and Gateway)
- Network Security Groups
- Network Interfaces
- Public IP
- Load Balancer with HTTP and HTTPS rules
- Two VMs (master and worker nodes)

## Notes

- The default VM size is Standard_B1s, which is suitable for a lightweight K3s cluster
- SSH public key path defaults to `~/.ssh/id_rsa.pub` - update this in variables.tf if needed
- The master node runs the K3s server while the worker node runs the K3s agent
- HTTP and HTTPS traffic is allowed through the load balancer 