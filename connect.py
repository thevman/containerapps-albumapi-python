import sys
import requests
import json
import logging
import time
import os
from dotenv import load_dotenv

logging.captureWarnings(True)

load_dotenv()
client_id = os.getenv('AZURE_CLIENT_ID')
client_secret = os.getenv('AZURE_CLIENT_SECRET')
tenant_id = os.getenv('AZURE_TENANT_ID')
api_url = os.getenv('API_URL')

test_api_url = os.getenv('CONTAINER_APP_URL')

##
##    function to obtain a new OAuth 2.0 token from the authentication server
##
def get_new_token():
    auth_server_url = "https://login.microsoftonline.com/"+ tenant_id +"/oauth2/v2.0/token"

    token_req_payload = {"grant_type": "client_credentials", \
                         "scope": api_url + "/.default"
                        }

    token_response = requests.post(auth_server_url,
        data=token_req_payload, verify=False, allow_redirects=True,
        auth=(client_id, client_secret))

    if token_response.status_code !=200:
      print("Failed to obtain token from the OAuth 2.0 server", file=sys.stderr)
      sys.exit(1)

    print("Successfuly obtained a new token")
    tokens = json.loads(token_response.text)
    return tokens['access_token']

## 
## 	obtain a token before calling the API for the first time
##
token = get_new_token()

api_call_headers = {'Authorization': 'Bearer ' + token}
api_call_response = requests.get(test_api_url, headers=api_call_headers, verify=False)
print('API Call response is: ' + api_call_response.text)

if	api_call_response.status_code == 401:
			token = get_new_token()
else:
    print('API Call response in else is: ' + api_call_response.text)
