# Azure K3s Terraform Deployment

## Overview
This project provisions a lightweight Kubernetes (K3s) cluster on Azure using Terraform. It sets up a master and worker VM, configures networking, security, and generates SSH keys for secure access. The setup is suitable for development, testing, and learning Kubernetes on Azure.

---

## Architecture
- **Azure Resources:**
  - Resource Group
  - Virtual Network & Subnets
  - Network Security Groups (NSGs) with recommended K3s rules
  - Public IPs for Load Balancer and Master VM
  - Azure Load Balancer (L4)
  - Linux Virtual Machines (Master & Worker)
- **K3s:**
  - Master node runs the K3s server
  - Worker node joins the cluster as an agent
  - Optional: Traefik ingress controller (disabled by default)

---

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription and credentials set up (see `providers.tf`)

---

## Terraform Configuration Walkthrough

This project is organized into several `.tf` files, each with a specific purpose. Below is a detailed explanation of each file and the main resources defined within:

### `providers.tf`
- **Purpose:** Configures the required Terraform providers and sets up the Azure provider with your subscription and tenant details.
- **Key Resources:**
  - `terraform { required_providers { ... } }`: Specifies the Azure, TLS, and Local providers.
  - `provider "azurerm" { ... }`: Configures Azure authentication.
  - `azurerm_resource_group.k3s`: Creates the resource group for all resources.

### `variables.tf`
- **Purpose:** Defines variables for customization, such as location, VM size, admin username, and network ranges.
- **Key Variables:**
  - `location`, `resource_group_name`, `admin_username`, `vm_size`, `vnet_address_space`, etc.

### `main.tf`
- **Purpose:** Entry point for the configuration and contains resources for generating SSH keys.
- **Key Resources:**
  - `tls_private_key.ssh`: Generates a new SSH key pair for VM access.
  - `local_file.private_key` and `local_file.public_key`: Save the generated keys to files in your project directory.

### `network.tf`
- **Purpose:** Defines all networking resources, including VNet, subnets, NSGs, and network interfaces.
- **Key Resources:**
  - `azurerm_virtual_network.k3s`: The main VNet for the cluster.
  - `azurerm_subnet.k3s` and `azurerm_subnet.gateway`: Subnets for K3s and gateway.
  - `azurerm_network_security_group.k3s` and `azurerm_network_security_group.gateway`: NSGs with detailed security rules for K3s operation (see below for rule details).
  - `azurerm_network_interface.master` and `azurerm_network_interface.worker`: NICs for the master and worker VMs.
  - `azurerm_network_interface_backend_address_pool_association.master`: Associates the master NIC with the load balancer backend pool.

### `loadbalancer.tf`
- **Purpose:** Sets up the Azure Load Balancer and related resources for external access and traffic distribution.
- **Key Resources:**
  - `azurerm_public_ip.lb`: Public IP for the load balancer.
  - `azurerm_lb.k3s`: The load balancer itself.
  - `azurerm_lb_backend_address_pool.k3s`: Backend pool for VM association.
  - `azurerm_lb_rule.ssh_master`, `azurerm_lb_rule.http`, `azurerm_lb_rule.https`: Rules for SSH, HTTP, and HTTPS traffic.
  - `azurerm_lb_probe.http`, `azurerm_lb_probe.https`: Health probes for HTTP/HTTPS.

### `compute.tf`
- **Purpose:** Defines the compute resources (VMs) for the K3s master and worker nodes.
- **Key Resources:**
  - `azurerm_linux_virtual_machine.master` and `azurerm_linux_virtual_machine.worker`: The VMs for the master and worker nodes, configured to use the generated SSH key and the latest Ubuntu LTS image.
  - `admin_ssh_key`: Injects the generated public key for secure access.
  - `os_disk` and `source_image_reference`: Disk and OS image configuration.
  - `provisioner` blocks (on master): Optionally copy the private key and set up SSH access from master to worker.

### `outputs.tf`
- **Purpose:** Defines outputs to make it easy to retrieve important information after deployment.
- **Key Outputs:**
  - `ssh_to_master_cmd`: SSH command for accessing the master VM.
  - `ssh_to_worker_from_master_cmd`: SSH command for accessing the worker from the master.
  - `master_vm_public_ip`, `worker_vm_private_ip`, etc.
  - `ssh_private_key_path`: Path to the generated SSH private key.

---

## Example: How the Pieces Fit Together
1. **Terraform generates an SSH key pair** and saves it locally.
2. **Azure resources are provisioned:**
   - Resource group, VNet, subnets, NSGs, public IPs, load balancer, and VMs.
3. **NSG rules** ensure that all required K3s ports are open between nodes for cluster communication.
4. **VMs are created** with the generated SSH key for secure access.
5. **Outputs** provide you with ready-to-use SSH commands and IP addresses.
6. **You install K3s** on the master and join the worker using the provided instructions.

---

## SSH Access

### SSH to Master VM
```sh
ssh -i ./k3s_ssh_key wush@<master_vm_public_ip>
```
(Replace `<master_vm_public_ip>` with the value from Terraform outputs)

### SSH to Worker VM (from Master)
```sh
ssh wush@<worker_vm_private_ip>
```

---

## K3s Installation

### On Master Node
Install K3s server (with Traefik disabled and kubeconfig readable by all users):
```sh
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable=traefik --write-kubeconfig-mode 644" sh -
```

### On Worker Node
1. Get the K3S token from the master:
   ```sh
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```
2. On the worker node, join the cluster:
   ```sh
   curl -sfL https://get.k3s.io | K3S_URL=https://<master_vm_private_ip>:6443 K3S_TOKEN=<token> sh -
   ```
   Replace `<master_vm_private_ip>` and `<token>` with your actual values.

### GitOps with Flux CD

To bootstrap Flux CD for GitOps automation:

```sh
flux bootstrap github \
  --owner=wussh \
  --repository=terraform-azure-k3s-cluster \
  --branch=main \
  --path=clusters/azure \
  --personal
```

To install the Flux CLI and enable bash completion:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash

# Enable bash completion for Flux (add to your ~/.bashrc for persistence)
. <(flux completion bash)
```

To use `kubectl` and Flux with your K3s cluster, export the kubeconfig (replace `<master_vm_public_ip>` with your actual value):

```sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Now you can use `kubectl` and `flux` commands to interact with your cluster.

---

## Network Security Group (NSG) Rules
The following ports are allowed between nodes for K3s operation (see `network.tf`):
- **TCP 22:** SSH
- **TCP 6443:** Kubernetes API server
- **TCP 2379-2380:** etcd (HA only)
- **UDP 8472:** Flannel VXLAN
- **TCP 10250:** Kubelet metrics
- **UDP 51820:** Flannel Wireguard IPv4
- **UDP 51821:** Flannel Wireguard IPv6
- **TCP 5001:** Embedded registry (Spegel)
- **TCP 6443:** Embedded registry (Spegel)

These rules are defined in the `azurerm_network_security_group.k3s` resource and ensure proper communication between all cluster nodes.

## Load Balancer Connectivity

For the Azure Load Balancer to properly forward HTTP and HTTPS traffic to your cluster services, ensure the following NSG rules are added to the `nsg-k3s` security group:

- **TCP 80 (HTTP):** Allow inbound HTTP traffic from any source
- **TCP 443 (HTTPS):** Allow inbound HTTPS traffic from any source

These rules are essential for the load balancer to route external traffic to your ingress controllers (like Traefik) running in the cluster. Without these rules, your services will not be accessible from the internet even if they're properly exposed through ingress resources.

If you're unable to access your services through the load balancer's public IP or a domain pointing to it, verify these rules are present in your NSG configuration:

```sh
az network nsg rule list -g <resource_group_name> --nsg-name nsg-k3s --query "[?destinationPortRange=='80' || destinationPortRange=='443']"
```

If no rules are returned, add them using:

```sh
az network nsg rule create \
  --resource-group <resource_group_name> \
  --nsg-name nsg-k3s \
  --name allow-http \
  --priority 210 \
  --protocol Tcp \
  --destination-port-range 80 \
  --access Allow

az network nsg rule create \
  --resource-group <resource_group_name> \
  --nsg-name nsg-k3s \
  --name allow-https \
  --priority 220 \
  --protocol Tcp \
  --destination-port-range 443 \
  --access Allow
```

## Istio Service Mesh

This project includes support for deploying Istio as a service mesh alongside Traefik. The architecture follows this pattern:

```
Internet
   ↓
Cloudflare (istio.wush.site → Public IP)
   ↓
[ Traefik (LoadBalancer @ 80/443) ]
   ↓
Routing by Host(`istio.wush.site`)
   ↓
[ Istio Gateway (ClusterIP @ 80/443) ]
   ↓
[ Istio Service Mesh ]
```

This architecture provides several benefits:
- Single entry point through Traefik for all external traffic
- Simplified network security with standard ports (80/443)
- Traefik handles TLS termination and external routing
- Istio focuses on internal service mesh capabilities and traffic management

### Detailed Traffic Flow

Here's a detailed breakdown of how traffic flows through the system:

1. **External Request**:
   - User makes a request to `http://istio.wush.site`
   - DNS resolves to Azure Load Balancer IP

2. **Azure Load Balancer**:
   - Receives traffic on port 80/443
   - Routes to Kubernetes nodes based on `loadbalancer.tf` rules
   - Both master and worker nodes are in the backend pool

3. **Traefik Ingress Controller**:
   - Runs as a LoadBalancer service in the cluster
   - Examines the Host header (`istio.wush.site`)
   - Matches the IngressRoute in `istio-system` namespace

4. **Traefik IngressRoute**:
   - Routes traffic to the Istio Gateway service
   - Must be in the same namespace as the target service (security constraint)
   - Uses `passHostHeader: true` to preserve the original host header

5. **Istio Gateway Service**:
   - ClusterIP service that forwards to the Istio Gateway pod
   - Internal to the cluster (not directly exposed to internet)

6. **Istio Gateway Resource**:
   - Defines which hosts and ports to accept
   - Routes traffic based on the host header

7. **Istio VirtualService**:
   - Routes traffic to the appropriate backend service
   - Can apply traffic policies, retries, timeouts, etc.

8. **Application Service**:
   - Receives the request and forwards to application pods
   - Pods have Istio sidecars for mesh features

### Installing Istio

Istio is deployed using Flux CD with the following components:

1. **istio-base:** Core CRDs and configurations
2. **istiod:** Istio control plane with auto sidecar injection
3. **istio-gateway:** Ingress gateway for internal service mesh traffic (ClusterIP)

The Helm release configurations are in `releases/azure/core/istio/release.yaml`.

### Network Security Group Rules

The NSG rules for standard HTTP/HTTPS traffic are sufficient as all external traffic goes through Traefik:

```sh
az network nsg rule create \
  --resource-group <resource_group_name> \
  --nsg-name nsg-k3s \
  --name allow-http \
  --priority 210 \
  --protocol Tcp \
  --destination-port-range 80 \
  --access Allow

az network nsg rule create \
  --resource-group <resource_group_name> \
  --nsg-name nsg-k3s \
  --name allow-https \
  --priority 220 \
  --protocol Tcp \
  --destination-port-range 443 \
  --access Allow
```

### Traefik to Istio Integration

To route traffic from Traefik to the Istio Gateway, create a Traefik IngressRoute:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: istio-gateway-route
  namespace: istio-system  # MUST be in same namespace as target service
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(`istio.wush.site`)
      kind: Rule
      services:
        - name: istio-gateway
          port: 80
          passHostHeader: true  # Important to preserve host header
```

### Using Istio Gateway

To expose a service through the Istio Gateway, create Gateway and VirtualService resources:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  selector:
    app: istio-gateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "istio.wush.site"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - "istio.wush.site"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-service
  namespace: my-namespace
spec:
  hosts:
  - "istio.wush.site"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - route:
    - destination:
        host: my-service.my-namespace.svc.cluster.local
        port:
          number: 80
```

Access your service at `http://istio.wush.site` or `https://istio.wush.site` through Traefik, which will route to the Istio Gateway.

### Troubleshooting the Traefik-Istio Integration

If you encounter issues with the Traefik to Istio Gateway routing:

1. **Check Traefik IngressRoute Namespace**:
   - The IngressRoute MUST be in the same namespace as the target service
   - Traefik security prevents cross-namespace service targeting by default
   ```sh
   kubectl get ingressroute -A
   ```

2. **Verify Host Header Passing**:
   - Ensure `passHostHeader: true` is set in the IngressRoute
   - Istio Gateway needs the original host header to match routes

3. **Check Traefik Logs**:
   ```sh
   kubectl logs -n internal deploy/traefik
   ```
   Look for errors like: `service istio-system/istio-gateway not in the parent resource namespace`

4. **Test Direct Access to Services**:
   ```sh
   # Test nginx service directly
   kubectl port-forward -n internal svc/nginx 8888:80
   curl http://localhost:8888
   
   # Test Istio Gateway service from within the cluster
   kubectl exec -it -n internal deploy/nginx -- curl -v http://istio-gateway.istio-system.svc.cluster.local
   ```

5. **Verify Istio Gateway Configuration**:
   ```sh
   kubectl get gateway -n istio-system
   kubectl get virtualservice -A
   ```
   Ensure the Gateway is configured to accept traffic for your host

6. **Check Istio Gateway Logs**:
   ```sh
   kubectl logs -n istio-system deploy/istio-gateway
   ```
   Look for connection attempts and any errors

---

## Troubleshooting

### Check if K3s is running (on master):
```sh
sudo systemctl status k3s
```

### Check if API server is listening on port 6443:
```sh
sudo ss -tulnp | grep 6443
```

### Test connectivity from worker to master:
```sh
nc -zv <master_vm_private_ip> 6443
```
Should show `succeeded!` or `Connected` if open.

### Check firewall status (on master):
```sh
sudo ufw status
sudo systemctl status firewalld
```

---

## References
- [K3s Documentation](https://rancher.com/docs/k3s/latest/en/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [K3s on Azure Guide](https://rancher.com/docs/k3s/latest/en/installation/)

---

## License
MIT 