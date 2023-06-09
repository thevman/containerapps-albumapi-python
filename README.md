# Azure Container Apps Album API

## Installation
* Start with creating the environment by running the following command:
  ````bash
    ./containerApp.sh
  ````
* Note the url in the output command eg: https://album-api.jollyhill-21e7637e.canadacentral.azurecontainerapps.io/
* Test the album api using _\<app-url\>_/albums

## Adding AD Authentication

### Create an app registration in Azure AD for your container app
1. Sign into the Azure Portal and select Azure Active Directory, then go to the App registrations tab and select New registration.
2. In the Register an application page, enter a Name for your app registration.
3. In Redirect URI, select Web and type _\<app-url\>_/.auth/login/aad/callback. For example, https://\<hostname\>.azurecontainerapps.io/.auth/login/aad/callback.
4. Select Register.
5. After the app registration is created, copy the Application (client) ID and the Directory (tenant) ID for later. eg:
````yaml
Application (client) ID: 738d3dbd-5c4b-4d6d-8e5f-7765280795e0
Directory (tenant) ID: ff87514a-dc3e-4e9a-a805-fa5dd9b76e28
````
6. Select Authentication. Under Implicit grant and hybrid flows, enable ID tokens to allow OpenID Connect user sign-ins from Container Apps. Select Save.
![Enable Id Tokens](./images/Screenshot%202023-06-08%20at%2012.34.49%20PM.png)
7. Select Expose an API, and select Add next to Application ID URI and click Save. 
![Enable Id Tokens](./images/Screenshot%202023-06-08%20at%2012.41.31%20PM.png)
    This value uniquely identifies the application when it's used as a resource, allowing tokens to be requested that grant access. The value is also used as a prefix for scopes you create.For a single-tenant app, you can use the default value, which is in the form api://\<application-client-id\>.

__Important:__ Make a note of the application-client-id. You will need to send this to the development team for authentication.

8. Select Add a scope.
    1. In Add a scope, the Application ID URI is the value you set in a previous step. Select Save and continue.
    2. In Scope name, enter user_impersonation.
    3. In the text boxes, enter the consent scope name and description you want users to see on the consent page. For example, enter Access \<application-name\>.
    4. Select Add scope.

#### Enable App Roles
1. Sign in to the Azure portal.
2. Search for and select Azure Active Directory.
3. Under Manage, select App registrations, and then select the application you want to define app roles in.
4. Select App roles, and then select Create app role.
5. In the Create app role pane, enter the following values for the role:
    * Display name: Writers
    * Allowed member types: Applications
    * Value: Write
    * Description: Ability to write to the application
    * Do you want to enable this app role: Yes
6. Select Apply to save your changes.

<span style="color: red;"> __Important:__ Roles ensure that only certain applications within the tenant are allowed access to the api. To be implemented successfully, the application code needs to define an authentication model which corresponds to the roles defined here.</span>

#### Authorization
1. On the app registration representing the client that needs to be authorized, select API permissions > Add a permission > My APIs.
2. Select the app registration you created earlier. If you don't see the app registration, make sure that you've added an App Role.
3. Under Application permissions, select the App Role you created earlier, and then select Add permissions.
4. Make sure to select Grant admin consent to authorize the client application to request the permission.


### Enable Azure Active Directory in your container app

1. Sign in to the Azure portal and navigate to your app.
2. Select Authentication in the menu on the left. Select Add identity provider.
3. Select Microsoft in the identity provider dropdown.
4. For App registration type, choose "Pick an existing app registration in this directory" which will automatically gather the necessary app information. Select the app you just created and click "Add"

## Daemon client application (service-to-service calls)

1. In the Azure portal, select Active Directory > App registrations > New registration.
2. In the Register an application page, enter a Name for your daemon app registration.
3. For a daemon application, you don't need a Redirect URI so you can keep that empty.
4. Select Register.
5. After the app registration is created, copy the value of Application (client) ID.
6. Select Certificates & secrets > New client secret and put in the following values:
    * Description: dameon-client-secret
    * Expires: 365 Days (12 months)
7. Click Add 
8. Copy the client secret value shown in the page. It won't be shown again.
9. Save the client id and secret into pstate. 

### Assign app roles to Daemon client application
1. Sign in to the Azure portal.
2. In Azure Active Directory, select App registrations in the left-hand navigation menu.
3. Select the application to which you want to assign an app role.
4. Select API permissions > Add a permission.
5. Select the My APIs tab, and then select the app for which you defined app roles.
6. Select Application permissions.
7. Select the role(s) you want to assign.
8. Select the Add permissions button complete addition of the role(s).
9. The newly added roles should appear in your app registration's API permissions pane.


## Client Code Sample
The following sample code has been tested and is working:

### Pre-Requisites:
Get values for the following:
* AZURE_CLIENT_ID: The application ID of the Daemon Client Application
* AZURE_CLIENT_SECRET: The Client Secret for the Daemon Client Application

__NOTE:__ The above two values can also be retrieved from pstate. 
* AZURE_TENANT_ID: The tenant ID for the mda tenant
* API_URL: The Client ID retrieved on step 5 of "Create an app registration in Azure AD for your container app"
* CONTAINER_APP_URL: The complete url of the container App including the container app URI as well as any path required. 

### Code
* Create a .env file with the following:
    ````bash
    AZURE_CLIENT_ID     = 'daemon_application_client_id'
    AZURE_CLIENT_SECRET ='daemon_applicattion_client_secret'
    AZURE_TENANT_ID     = 'tenant_id'
    API_URL             ='application_id'
    CONTAINER_APP_URL   ="complete_container_app_url"

    ````

* Create a python file with the following contents:
    ````python
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

    ````
* Save the file as connect_test.py
* Run the python file with the following command:
    ````bash
        python3 connect_test.py
    ````
