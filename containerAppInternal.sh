#!/bin/bash

RESOURCE_GROUP="album-ca-internal"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="containerapps-internal"
VNET_NAME="containerapp-internal-vnet"
GITHUB_USERNAME="thevman"
ACR_NAME="acainternalalbums"$GITHUB_USERNAME
API_NAME="internal-album-api"
WORKSPACE_NAME="la-"$CONTAINERAPPS_ENVIRONMENT
VM_NAME="testVm"
az login -t "ff87514a-dc3e-4e9a-a805-fa5dd9b76e28"

az group create --name $RESOURCE_GROUP --location $LOCATION

az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

az acr build --registry $ACR_NAME --image $API_NAME ./src

az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name infrastructure-subnet \
  --address-prefixes 10.0.0.0/23

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name test-subnet \
  --address-prefixes 10.0.3.0/24

INFRASTRUCTURE_SUBNET=`az network vnet subnet show --resource-group ${RESOURCE_GROUP} --vnet-name $VNET_NAME --name infrastructure-subnet --query "id" -o tsv | tr -d '[:space:]'`

az monitor log-analytics workspace create -g $RESOURCE_GROUP -n $WORKSPACE_NAME

WORKSPACE_ID=`az monitor log-analytics workspace show --resource-group ${RESOURCE_GROUP} --workspace-name ${WORKSPACE_NAME} --query customerId -o tsv`

WORKSPACE_KEY=`az monitor log-analytics workspace get-shared-keys --resource-group ${RESOURCE_GROUP} --workspace-name ${WORKSPACE_NAME} --query "primarySharedKey" -o tsv`

az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --logs-workspace-id $WORKSPACE_ID \
  --logs-workspace-key $WORKSPACE_KEY \
  --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET \
  --internal-only

ENVIRONMENT_DEFAULT_DOMAIN=`az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.defaultDomain --out json | tr -d '"'`
ENVIRONMENT_STATIC_IP=`az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.staticIp --out json | tr -d '"'`
VNET_ID=`az network vnet show --resource-group ${RESOURCE_GROUP} --name ${VNET_NAME} --query id --out json | tr -d '"'`

az network private-dns zone create \
  --resource-group $RESOURCE_GROUP \
  --name $ENVIRONMENT_DEFAULT_DOMAIN

az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --virtual-network $VNET_ID \
  --zone-name $ENVIRONMENT_DEFAULT_DOMAIN -e true

az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP \
  --record-set-name "*" \
  --ipv4-address $ENVIRONMENT_STATIC_IP \
  --zone-name $ENVIRONMENT_DEFAULT_DOMAIN


az containerapp create \
  --name $API_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image $ACR_NAME.azurecr.io/$API_NAME \
  --target-port 3500 \
  --transport http2 \
  --ingress 'internal' \
  --registry-server $ACR_NAME.azurecr.io \
  --query properties.configuration.ingress.fqdn


az vm create -n $VM_NAME -g $RESOURCE_GROUP \
 --image Ubuntu2204 \
 --public-ip-address "${VM_NAME}-public-ip" \
 --public-ip-sku Standard \
 --vnet-name $VNET_NAME --subnet test-subnet \
 --size Standard_B2s \
 --nic-delete-option true \
 --generate-ssh-keys