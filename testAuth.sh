#!/bin/bash

#pip3 install python-dotenv
#pip3 install azure-identity
export AZURE_CLIENT_ID="8d3194fb-bb13-4924-bdbf-721d439da060"
export AZURE_TENANT_ID="ff87514a-dc3e-4e9a-a805-fa5dd9b76e28"
export AZURE_CLIENT_SECRET="hCO8Q~2zWTlPgeg06kqHgZz2Knp~SR0iiswcbbPn"

#api%3A%2F%2F738d3dbd-5c4b-4d6d-8e5f-7765280795e0
# Replace {tenant} with your tenant!
token=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$AZURE_CLIENT_ID&\
        scope=738d3dbd-5c4b-4d6d-8e5f-7765280795e0%2F.default&\
        client_secret=$AZURE_CLIENT_SECRET\
        &grant_type=client_credentials" \
        "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" | jq -r .access_token)
echo $token

header="Authorization: Bearer $token"
echo $header
curl -X GET -H "$header" \
        https://album-api.jollyhill-21e7637e.canadacentral.azurecontainerapps.io/albums