#!/usr/bin/env bash
set -euo pipefail

# ============
# Parâmetros
# ============
LOCATION="${LOCATION:-brazilsouth}"         # ex: brazilsouth, eastus
RG="${RG:-rg-hubspoke-demo}"

# Alternar criação de VMs (true/false)
CREATE_VMS=${CREATE_VMS:-false}

# Tamanho das VMs e SO
VM_SIZE="${VM_SIZE:-Standard_B1s}"
VM_IMAGE="${VM_IMAGE:-UbuntuLTS}"
ADMIN_USER="${ADMIN_USER:-azureuser}"

# Fonte para SSH (ajuste para seu IP: "203.0.113.45/32")
SSH_SOURCE_PREFIX="${SSH_SOURCE_PREFIX:-*}"

# ============
# Nomes
# ============
VNET_HUB="vnet-hub"
VNET_SPOKE1="vnet-spoke1"
VNET_SPOKE2="vnet-spoke2"

# Subnets HUB
SNET_HUB_1="hub-subnet1"    # 10.0.0.0/26
SNET_HUB_2="hub-subnet2"    # 10.0.0.64/26

# Subnets SPOKE1
SNET_S1_APP="spoke1-app"    # 10.1.0.0/26
SNET_S1_DB="spoke1-db"      # 10.1.0.64/26

# Subnets SPOKE2
SNET_S2_APP="spoke2-app"    # 10.2.0.0/26
SNET_S2_DB="spoke2-db"      # 10.2.0.64/26

# Route Tables (uma por subnet)
RT_HUB_1="rt-${SNET_HUB_1}"
RT_HUB_2="rt-${SNET_HUB_2}"
RT_S1_APP="rt-${SNET_S1_APP}"
RT_S1_DB="rt-${SNET_S1_DB}"
RT_S2_APP="rt-${SNET_S2_APP}"
RT_S2_DB="rt-${SNET_S2_DB}"

# NSGs (um por subnet)
NSG_HUB_1="nsg-${SNET_HUB_1}"
NSG_HUB_2="nsg-${SNET_HUB_2}"
NSG_S1_APP="nsg-${SNET_S1_APP}"
NSG_S1_DB="nsg-${SNET_S1_DB}"
NSG_S2_APP="nsg-${SNET_S2_APP}"
NSG_S2_DB="nsg-${SNET_S2_DB}"

echo ">> Iniciando implantação no RG=$RG, Região=$LOCATION"

# ============
# Resource Group
# ============
echo ">> Criando Resource Group"
az group create -n "$RG" -l "$LOCATION" --only-show-errors 1>/dev/null

# ============
# VNETs + Subnets
# ============
echo ">> Criando VNet HUB e subnets"
az network vnet create -g "$RG" -n "$VNET_HUB" -l "$LOCATION" \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name "$SNET_HUB_1" --subnet-prefixes 10.0.0.0/26 \
  --only-show-errors 1>/dev/null

az network vnet subnet create -g "$RG" --vnet-name "$VNET_HUB" -n "$SNET_HUB_2" \
  --address-prefixes 10.0.0.64/26 \
  --only-show-errors 1>/dev/null

echo ">> Criando VNet SPOKE1 e subnets"
az network vnet create -g "$RG" -n "$VNET_SPOKE1" -l "$LOCATION" \
  --address-prefixes 10.1.0.0/16 \
  --subnet-name "$SNET_S1_APP" --subnet-prefixes 10.1.0.0/26 \
  --only-show-errors 1>/dev/null

az network vnet subnet create -g "$RG" --vnet-name "$VNET_SPOKE1" -n "$SNET_S1_DB" \
  --address-prefixes 10.1.0.64/26 \
  --only-show-errors 1>/dev/null

echo ">> Criando VNet SPOKE2 e subnets"
az network vnet create -g "$RG" -n "$VNET_SPOKE2" -l "$LOCATION" \
  --address-prefixes 10.2.0.0/16 \
  --subnet-name "$SNET_S2_APP" --subnet-prefixes 10.2.0.0/26 \
  --only-show-errors 1>/dev/null

az network vnet subnet create -g "$RG" --vnet-name "$VNET_SPOKE2" -n "$SNET_S2_DB" \
  --address-prefixes 10.2.0.64/26 \
  --only-show-errors 1>/dev/null

# ============
# Route Tables + associação
# ============
echo ">> Criando Route Tables e associando"
# HUB
az network route-table create -g "$RG" -n "$RT_HUB_1" --only-show-errors 1>/dev/null
az network route-table create -g "$RG" -n "$RT_HUB_2" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_HUB" -n "$SNET_HUB_1" --route-table "$RT_HUB_1" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_HUB" -n "$SNET_HUB_2" --route-table "$RT_HUB_2" --only-show-errors 1>/dev/null
# SPOKE1
az network route-table create -g "$RG" -n "$RT_S1_APP" --only-show-errors 1>/dev/null
az network route-table create -g "$RG" -n "$RT_S1_DB"  --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE1" -n "$SNET_S1_APP" --route-table "$RT_S1_APP" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE1" -n "$SNET_S1_DB"  --route-table "$RT_S1_DB"  --only-show-errors 1>/dev/null
# SPOKE2
az network route-table create -g "$RG" -n "$RT_S2_APP" --only-show-errors 1>/dev/null
az network route-table create -g "$RG" -n "$RT_S2_DB"  --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE2" -n "$SNET_S2_APP" --route-table "$RT_S2_APP" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE2" -n "$SNET_S2_DB"  --route-table "$RT_S2_DB"  --only-show-errors 1>/dev/null

# ============
# NSGs por Subnet + Regras
# ============
echo ">> Criando NSGs por subnet e associando"

# Função helper para abrir SSH
create_ssh_rule () {
  local nsg="$1"
  local priority="$2"
  az network nsg rule create -g "$RG" --nsg-name "$nsg" \
    -n allow-ssh-internet --priority "$priority" \
    --access Allow --direction Inbound --protocol Tcp \
    --source-address-prefixes "$SSH_SOURCE_PREFIX" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges 22 \
    --only-show-errors 1>/dev/null
}

# Função helper para negar SSH da Internet (DB)
deny_ssh_internet_rule () {
  local nsg="$1"
  local priority="$2"
  az network nsg rule create -g "$RG" --nsg-name "$nsg" \
    -n deny-ssh-internet --priority "$priority" \
    --access Deny --direction Inbound --protocol Tcp \
    --source-address-prefixes Internet \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges 22 \
    --only-show-errors 1>/dev/null
}

# Criar NSGs
for NSG in "$NSG_HUB_1" "$NSG_HUB_2" "$NSG_S1_APP" "$NSG_S1_DB" "$NSG_S2_APP" "$NSG_S2_DB"; do
  az network nsg create -g "$RG" -n "$NSG" -l "$LOCATION" --only-show-errors 1>/dev/null
done

# Regras:
# - HUB_1 (onde ficará VM com PIP): permite SSH da Internet (ajuste SSH_SOURCE_PREFIX)
create_ssh_rule "$NSG_HUB_1" 1000
# - HUB_2: nenhuma regra extra (defaults: AllowVNetInBound; DenyAllInBound)
# - SPOKE1 APP: permite SSH da Internet (para VM APP com PIP)
create_ssh_rule "$NSG_S1_APP" 1000
# - SPOKE1 DB: nega SSH da Internet explicitamente
deny_ssh_internet_rule "$NSG_S1_DB" 1000
# - SPOKE2 APP: permite SSH da Internet (para VM APP com PIP)
create_ssh_rule "$NSG_S2_APP" 1000
# - SPOKE2 DB: nega SSH da Internet explicitamente
deny_ssh_internet_rule "$NSG_S2_DB" 1000

# Associar NSGs às subnets
az network vnet subnet update -g "$RG" --vnet-name "$VNET_HUB"   -n "$SNET_HUB_1" --network-security-group "$NSG_HUB_1" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_HUB"   -n "$SNET_HUB_2" --network-security-group "$NSG_HUB_2" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE1" -n "$SNET_S1_APP" --network-security-group "$NSG_S1_APP" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE1" -n "$SNET_S1_DB"  --network-security-group "$NSG_S1_DB"  --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE2" -n "$SNET_S2_APP" --network-security-group "$NSG_S2_APP" --only-show-errors 1>/dev/null
az network vnet subnet update -g "$RG" --vnet-name "$VNET_SPOKE2" -n "$SNET_S2_DB"  --network-security-group "$NSG_S2_DB"  --only-show-errors 1>/dev/null

# ============
# Peering HUB-SPOKES
# ============
echo ">> Criando Peering HUB <-> Spoke1 e HUB <-> Spoke2"
az network vnet peering create -g "$RG" -n hub-to-spoke1 \
  --vnet-name "$VNET_HUB" --remote-vnet "$VNET_SPOKE1" --allow-vnet-access --only-show-errors 1>/dev/null
az network vnet peering create -g "$RG" -n spoke1-to-hub \
  --vnet-name "$VNET_SPOKE1" --remote-vnet "$VNET_HUB" --allow-vnet-access --only-show-errors 1>/dev/null
az network vnet peering create -g "$RG" -n hub-to-spoke2 \
  --vnet-name "$VNET_HUB" --remote-vnet "$VNET_SPOKE2" --allow-vnet-access --only-show-errors 1>/dev/null
az network vnet peering create -g "$RG" -n spoke2-to-hub \
  --vnet-name "$VNET_SPOKE2" --remote-vnet "$VNET_HUB" --allow-vnet-access --only-show-errors 1>/dev/null

# ============
# VMs (com IP Público) — criadas somente se CREATE_VMS=true
# ============
if [[ "$CREATE_VMS" == "true" ]]; then
  echo ">> Criando VMs com IP Público (SSH liberado conforme NSG da subnet)"

  # HUB VM (subnet1) — cria PIP automaticamente
  az vm create -g "$RG" -n vm-hub-1 -l "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --vnet-name "$VNET_HUB" --subnet "$SNET_HUB_1" \
    --only-show-errors 1>/dev/null

  # SPOKE1 APP VM — cria PIP automaticamente
  az vm create -g "$RG" -n vm-spoke1-app -l "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --vnet-name "$VNET_SPOKE1" --subnet "$SNET_S1_APP" \
    --only-show-errors 1>/dev/null

  # SPOKE2 APP VM — cria PIP automaticamente
  az vm create -g "$RG" -n vm-spoke2-app -l "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --vnet-name "$VNET_SPOKE2" --subnet "$SNET_S2_APP" \
    --only-show-errors 1>/dev/null

  echo ">> VMs criadas com IP Público. Use 'az vm list-ip-addresses -g $RG -o table' para ver os IPs."
fi

# ============
# Resumo
# ============
echo ">> Concluído."
echo "Resource Group: $RG"
echo "VNets/Subnets:"
echo " - $VNET_HUB: $SNET_HUB_1(10.0.0.0/26), $SNET_HUB_2(10.0.0.64/26)"
echo " - $VNET_SPOKE1: $SNET_S1_APP(10.1.0.0/26), $SNET_S1_DB(10.1.0.64/26)"
echo " - $VNET_SPOKE2: $SNET_S2_APP(10.2.0.0/26), $SNET_S2_DB(10.2.0.64/26)"
echo "Peering: HUB<->SPOKE1 e HUB<->SPOKE2 — ATIVO"
echo "NSGs por subnet associados (SSH liberado nas APP e HUB_1; negado nas DB)"
echo "Route Tables associadas 1:1 com cada subnet"
if [[ "$CREATE_VMS" == "true" ]]; then
  echo "VMs: vm-hub-1, vm-spoke1-app, vm-spoke2-app (com IP Público)"
else
  echo "VMs: não criadas (defina CREATE_VMS=true para criar)."
fi
