import os
import requests

TOKEN = os.getenv('LEGACY_TOKEN')
INITIAL_USER_EMAIL = os.getenv('INITIAL_USER_EMAIL')
INITIAL_USER_PASSWORD = os.getenv('INITIAL_USER_PASSWORD')
INITIAL_ORGANIZATION_NAME = os.getenv('INITIAL_ORGANIZATION_NAME')

KEYCLOAK_ADMIN_API_CLIENT_SECRET = os.getenv('KEYCLOAK_ADMIN_API_CLIENT_SECRET')
KEYCLOAK_FRONTEND_URL = os.getenv('KEYCLOAK_FRONTEND_URL')

LAGOON_API_URL = os.getenv('LAGOON_API_URL')

seed_user_gql = f"""
mutation LagoonCoreSeeding {{

    CreatePlatformOwner: addUser(
        input: {{
            email: "{INITIAL_USER_EMAIL}"
        }}
    ) {{
        id
    }}

    GiveUserPlatformOwnerRole: addPlatformRoleToUser(
    user: {{
      email: "{INITIAL_USER_EMAIL}"
    }}
    role: OWNER
    ) {{
        email
        platformRoles
    }}
}}
"""

seed_org_gql = f"""
mutation LagoonCoreSeedOrg {{
    CreateOrganization: addOrganization(input: {{
        name: "{INITIAL_ORGANIZATION_NAME}"
    }}) {{
        id
    }}
}}
"""


def seed_org():
    print("Seeding Lagoon core with initial organization")

    lagoon_api_url = LAGOON_API_URL.replace("https://", "http://", 1)
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {TOKEN}"
    }

    response = requests.post(lagoon_api_url, json={"query": seed_org_gql}, headers=headers)
    body = response.json()
    print(body)
    try:
        org_id = body["data"]["CreateOrganization"]["id"]
        print(f"Created org with id {org_id}")
    except (KeyError, TypeError):
        print("Failed to extract organization ID from response:")
        print(body)
        return

    configure_org_graphql = f"""
mutation LagoonCoreConfigOrg {{
    CreateGroup: addGroup(input: {{
        name: "{INITIAL_ORGANIZATION_NAME}-group"
    }}) {{
        id
    }}

    AddUserToGroup: addUserToGroup(input: {{
        user: {{ email: "{INITIAL_USER_EMAIL}" }}
        group: {{ name: "{INITIAL_ORGANIZATION_NAME}-group" }}
        role: OWNER
    }}) {{
        name
    }}

    AddGroupToOrg: addExistingGroupToOrganization(input: {{
        name: "{INITIAL_ORGANIZATION_NAME}-group"
        organization: {org_id}
    }}) {{
        id
    }}

    AddUserToOrg: addAdminToOrganization(input: {{
        user: {{ email: "{INITIAL_USER_EMAIL}" }}
        organization: {{ id: {org_id} }}
        role: OWNER
    }}) {{
        id
    }}
}}
"""
    configure_response = requests.post(lagoon_api_url, json={"query": configure_org_graphql}, headers=headers)
    print(configure_response.json())


def seed_user():
    print("Seeding Lagoon core with initial user")

    lagoon_api_url = LAGOON_API_URL.replace("https://", "http://", 1)
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {TOKEN}"
    }

    response = requests.post(lagoon_api_url, json={"query": seed_user_gql}, headers=headers)
    print(response.json())

    keycloak_url = f"{KEYCLOAK_FRONTEND_URL}/auth".replace("https://", "http://", 1)
    print(f"Setting user password in keycloak at {keycloak_url}")

    data = {
            "grant_type": "client_credentials",
            "client_id": "admin-api",
            "client_secret": KEYCLOAK_ADMIN_API_CLIENT_SECRET
            }
    response = requests.post(f"{keycloak_url}/realms/master/protocol/openid-connect/token", data)
    if response.status_code != 200:
        print("Failed to get Keycloak access token")
        return
    else:
        print("Keycloak token successfully retrieved")

    token = response.json()["access_token"]
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    user_lookup = requests.get(f"{keycloak_url}/admin/realms/lagoon/users?email={INITIAL_USER_EMAIL}", headers=headers)
    if user_lookup.status_code != 200:
        print(f"Failed to user {INITIAL_USER_EMAIL} in Keycloak")
        return

    users = user_lookup.json()
    user_id = users[0]["id"]
    pw_data = {
        "type": "password",
        "value": INITIAL_USER_PASSWORD,
        "temporary": False
    }

    reset_pw = requests.put(
        f"{keycloak_url}/admin/realms/lagoon/users/{user_id}/reset-password",
        headers=headers,
        json=pw_data
    )

    if reset_pw.status_code == 204:
        print("Password set successfully!")
    else:
        print("Failed to set user password.")


seed_user()
if INITIAL_ORGANIZATION_NAME != "":
    seed_org()
