#!/bin/bash

#pip3 install python-dotenv
#pip3 install azure-identity
# This is the application id for the daemon app
export AZURE_CLIENT_ID="8d3194fb-bb13-4924-bdbf-721d439da060"
# This is the tenant id
export AZURE_TENANT_ID="ff87514a-dc3e-4e9a-a805-fa5dd9b76e28"
# This is the client secret for the daemon app
export AZURE_CLIENT_SECRET="hCO8Q~2zWTlPgeg06kqHgZz2Knp~SR0iiswcbbPn"
# This is the application id for the container app and not the damon client application id. 
export AZURE_APPLICATION_ID="738d3dbd-5c4b-4d6d-8e5f-7765280795e0"
# This is the container app url.
export CONTAINER_APP_URL="https://album-api.thankfulbay-3b3d8a71.canadacentral.azurecontainerapps.io/albums"

token=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$AZURE_CLIENT_ID&\
        scope=$AZURE_APPLICATION_ID%2F.default&\
        client_secret=$AZURE_CLIENT_SECRET\
        &grant_type=client_credentials" \
        "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" | jq -r .access_token)
echo $token

header="Authorization: Bearer $token"
echo $header
curl -X GET -H "$header" $CONTAINER_APP_URL