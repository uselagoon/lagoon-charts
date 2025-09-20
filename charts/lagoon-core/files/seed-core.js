const axios = require("axios");
const jwt = require("jsonwebtoken");

const {
  INITIAL_USER_EMAIL,
  INITIAL_USER_PASSWORD,
  INITIAL_ORGANIZATION_NAME,
  KEYCLOAK_ADMIN_API_CLIENT_SECRET,
  KEYCLOAK_FRONTEND_URL,
  LAGOON_API_URL,
  JWTUSER,
  JWTAUDIENCE,
  JWTSECRET
} = process.env;

const payload = {
  role: "admin",
  iss: JWTUSER,
  aud: JWTAUDIENCE,
  sub: JWTUSER
};

const TOKEN = jwt.sign(payload, JWTSECRET, { algorithm: "HS256" });

const seedUserGql = `
mutation LagoonCoreSeeding {
    CreatePlatformOwner: addUser(
        input: { email: "${INITIAL_USER_EMAIL}" }
    ) {
        id
    }

    GiveUserPlatformOwnerRole: addPlatformRoleToUser(
        user: { email: "${INITIAL_USER_EMAIL}" }
        role: OWNER
    ) {
        email
        platformRoles
    }
}
`;

const seedOrgGql = `
mutation LagoonCoreSeedOrg {
    CreateOrganization: addOrganization(input: {
        name: "${INITIAL_ORGANIZATION_NAME.toLocaleLowerCase().replace(/[^0-9a-z-]/g,'-')}"
        friendlyName: "${INITIAL_ORGANIZATION_NAME}"
    }) {
        id
    }
}
`;

async function waitForKeycloak(url, timeout = 600000, interval = 2000) {
  const start = Date.now();

  while (Date.now() - start < timeout) {
    try {
      const response = await axios.get(url);
      if (response.status === 200) {
        console.log("Connected to keycloak");
        return;
      }
    } catch (err) {
      console.log(`waiting for keycloak at ${url}...`);
    }
    await new Promise(resolve => setTimeout(resolve, interval));
  }

  throw new Error(`Timed out waiting for Keycloak at ${url}`);
}

async function seedOrg() {
  console.log("Seeding Lagoon core with initial organization");

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${TOKEN}`
  };

  try {
    const response = await axios.post(LAGOON_API_URL, { query: seedOrgGql }, { headers });
    const body = response.data;

    const orgId = body?.data?.CreateOrganization?.id;
    if (!orgId) {
      console.log("Failed to extract organization ID from response:");
      console.log(body);
      return;
    }

    console.log(`Created org with id ${orgId}`);
  } catch (err) {
    console.error("Error seeding organization:", err.response?.data || err.message);
  }
}

async function seedUser() {
  console.log("Seeding Lagoon core with initial user");

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${TOKEN}`
  };

  try {
    const response = await axios.post(LAGOON_API_URL, { query: seedUserGql }, { headers });

    await waitForKeycloak(KEYCLOAK_FRONTEND_URL + "/admin/master/console");
    console.log(`Setting user password in keycloak at ${KEYCLOAK_FRONTEND_URL}`);

    const data = new URLSearchParams({
      grant_type: "client_credentials",
      client_id: "admin-api",
      client_secret: KEYCLOAK_ADMIN_API_CLIENT_SECRET
    });

    const tokenResponse = await axios.post(
      `${KEYCLOAK_FRONTEND_URL}/realms/master/protocol/openid-connect/token`,
      data
    );

    if (tokenResponse.status !== 200) {
      console.log("Failed to get Keycloak access token");
      return;
    } else {
      console.log("Keycloak token successfully retrieved");
    }

    const token = tokenResponse.data.access_token;
    const keycloakHeaders = {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json"
    };

    const userLookup = await axios.get(
      `${KEYCLOAK_FRONTEND_URL}/admin/realms/lagoon/users?email=${INITIAL_USER_EMAIL}`,
      { headers: keycloakHeaders }
    );

    if (userLookup.status !== 200) {
      console.log(`Failed to find user ${INITIAL_USER_EMAIL} in Keycloak`);
      return;
    }

    const users = userLookup.data;
    const userId = users[0]?.id;
    if (!userId) {
      console.log("User not found in Keycloak");
      return;
    }

    const pwData = {
      type: "password",
      value: INITIAL_USER_PASSWORD,
      temporary: false
    };

    const resetPw = await axios.put(
      `${KEYCLOAK_FRONTEND_URL}/admin/realms/lagoon/users/${userId}/reset-password`,
      pwData,
      { headers: keycloakHeaders }
    );

    if (resetPw.status === 204) {
      console.log("Password set successfully!");
    } else {
      console.log("Failed to set user password.");
    }
  } catch (err) {
    console.error("Error seeding user:", err.response?.data || err.message);
  }
}

(async () => {
  if (INITIAL_USER_EMAIL && INITIAL_USER_PASSWORD) {
    await seedUser();
  }
  if (INITIAL_ORGANIZATION_NAME) {
    await seedOrg();
  }
})();

