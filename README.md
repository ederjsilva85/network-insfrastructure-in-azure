# network-insfrastructure-in-azure
This repository contains a Bash script using **Azure CLI** to deploy a basic **Hub-Spoke network topology** in Microsoft Azure.


<img width="60" height="60" alt="Microsoft_Azure svg" src="https://github.com/user-attachments/assets/807bf288-3268-4f0f-b300-12865e702d6f" />


# Azure Hub-Spoke Network Bootstrap

This repository contains a Bash script using **Azure CLI** to deploy a basic **Hub-Spoke network topology** in Microsoft Azure.

The main goal is to provide a **starting point** for network infrastructure that can later be expanded with additional services (e.g., firewalls, NVAs, Application Gateways, Load Balancers, Bastion, etc.).

---

## 🚀 What the script does

- **Resource Group**
  - Creates a single resource group (`rg-hubspoke-demo`) to hold all resources.

- **Virtual Networks**
  - 1 Hub VNet (`10.0.0.0/16`) with two subnets (/26 each).
  - 2 Spoke VNets (`10.1.0.0/16` and `10.2.0.0/16`), each with:
    - 1 Application subnet (/26).
    - 1 Database subnet (/26).

- **Route Tables**
  - One route table per subnet (empty by default, can be customized later).

- **NSGs (Network Security Groups)**
  - One NSG per subnet (6 in total).
  - App subnets and Hub Subnet1 allow inbound SSH (22/TCP) from Internet (can be restricted to your IP).
  - DB subnets deny inbound SSH explicitly.
  - Default rules allow intra-VNet and peered traffic.

- **VNet Peering**
  - Bidirectional peering between Hub ↔ Spoke1 and Hub ↔ Spoke2.

- **Virtual Machines (Optional)**
  - If enabled (`CREATE_VMS=true`):
    - 1 VM in Hub Subnet1.
    - 1 VM in Spoke1 App subnet.
    - 1 VM in Spoke2 App subnet.
  - All VMs are provisioned with a public IP and SSH access.

---


## 🛠 Usage

1. Save the script as `deploy-hubspoke.sh`.
2. Run in **Azure Cloud Shell (Bash)** or on your local machine with Azure CLI installed.

- Deploy without VMs:
  ```bash
  ./deploy-hubspoke.sh
  
  

## Deploy with VMs (replace with your admin username):

- Deploy with VMs:
  ```bash
  CREATE_VMS=true ADMIN_USER=azureuser ./deploy-hubspoke.sh

## Deploy with VMs and Restrict SSH access to your IP only:

- Deploy with VMs and restrict to SSH:
  ```bash
  SSH_SOURCE_PREFIX="YOUR-IP/32" CREATE_VMS=true ADMIN_USER=azureuser ./deploy-hubspoke.sh


## 🧹 Clean Up

- Clean Up:
  ```bash
    az group delete -n rg-hubspoke-demo --yes --no-wait


## ⚡ Next Steps

This initial network foundation can be expanded with:

Azure Firewall or NVA in the Hub.

User Defined Routes (UDR) to force traffic through security appliances.

VPN Gateway or ExpressRoute for hybrid connectivity.

Application Gateway, Load Balancers, Bastion for secure remote access.

Private DNS zones and Service Endpoints.


