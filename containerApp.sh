#!/bin/bash

export RESOURCE_GROUP="album-containerapps"
export LOCATION="canadacentral"
export ENVIRONMENT="env-album-containerapps"
export API_NAME="album-api"
export FRONTEND_NAME="album-ui"
export GITHUB_USERNAME="thevman"
export ACR_NAME="acaalbums"$GITHUB_USERNAME


az login -t "ff87514a-dc3e-4e9a-a805-fa5dd9b76e28"

az group create --name $RESOURCE_GROUP --location "$LOCATION"

az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

az acr build --registry $ACR_NAME --image $API_NAME .

az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION"

az containerapp create \
  --name $API_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_NAME.azurecr.io/$API_NAME \
  --target-port 3500 \
  --ingress 'external' \
  --registry-server $ACR_NAME.azurecr.io \
  --query properties.configuration.ingress.fqdn