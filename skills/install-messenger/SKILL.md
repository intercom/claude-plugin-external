---
name: install-messenger
description: >
  This skill should be used when the user asks to "install Intercom",
  "add the Intercom Messenger", "set up Intercom chat widget",
  "add customer chat to my website", or "integrate Intercom" into
  their website or application.
disable-model-invocation: true
argument-hint: "[framework]"
---

# Install Intercom Messenger

Help the user install the Intercom Messenger on their website or application with JWT-based identity verification. This is the secure default — it prevents user impersonation by cryptographically signing user identity on the server.

Only use the insecure (non-JWT) installation if the user explicitly asks for an "insecure installation". Never default to it.

## Requirements

Gather these from the user before proceeding:

1. **Workspace ID** (also called App ID) — A short alphanumeric string like `abc12345`.
   - Found in Intercom: **Settings > Installation > Web**
   - Or in the URL bar: `https://app.intercom.com/a/apps/<workspace_id>/...`

2. **Identity Verification Secret** (also called Messenger API Secret) — Found in Intercom at **Settings > Channels > Messenger > Security**. This is the HMAC secret used to sign JWTs. It must never appear in frontend code.

Ask the user for both values. Do not proceed without the Workspace ID. If they don't have the Identity Verification Secret yet, direct them to **Settings > Channels > Messenger > Security** in Intercom to enable it.

## Installation Overview

The secure installation has two parts:

1. **Backend**: Create an API endpoint that generates a signed JWT for the current authenticated user
2. **Frontend**: Boot the Messenger with the JWT from the backend

Always implement both parts. The backend generates the JWT; the frontend passes it to the Messenger.

## Step 1: Backend — JWT Generation Endpoint

Create a server-side endpoint that the frontend calls to get a signed JWT for the currently authenticated user. The JWT must be signed with **HS256** using the Identity Verification Secret.

### Required JWT Claims

| Claim | Required | Description |
|-------|----------|-------------|
| `user_id` | Yes | Stable, unique identifier for the user. Must match across sessions. |
| `email` | Recommended | User's email address |
| `name` | Recommended | User's display name |
| `exp` | Recommended | Expiration timestamp (Unix seconds). Use short-lived tokens — 2 hours is reasonable. |

**Important**: `user_id` is mandatory. If multiple users share the same email and you only pass `email` without `user_id`, Intercom will reject the request with a conflict error.

### Node.js / Express Example

```javascript
const jwt = require('jsonwebtoken');

const INTERCOM_SECRET = process.env.INTERCOM_IDENTITY_SECRET; // Never hardcode this

app.get('/api/intercom-jwt', requireAuth, (req, res) => {
  const token = jwt.sign(
    {
      user_id: req.user.id,
      email: req.user.email,
      name: req.user.name,
      exp: Math.floor(Date.now() / 1000) + (2 * 60 * 60), // 2 hours
    },
    INTERCOM_SECRET,
    { algorithm: 'HS256' }
  );

  res.json({ token });
});
```

### Python / Flask Example

```python
import jwt
import time
import os

INTERCOM_SECRET = os.environ['INTERCOM_IDENTITY_SECRET']

@app.route('/api/intercom-jwt')
@login_required
def intercom_jwt():
    token = jwt.encode(
        {
            'user_id': str(current_user.id),
            'email': current_user.email,
            'name': current_user.name,
            'exp': int(time.time()) + 7200,  # 2 hours
        },
        INTERCOM_SECRET,
        algorithm='HS256',
    )
    return {'token': token}
```

### Ruby / Rails Example

```ruby
# app/controllers/api/intercom_controller.rb
class Api::IntercomController < ApplicationController
  before_action :authenticate_user!

  def jwt
    token = JWT.encode(
      {
        user_id: current_user.id.to_s,
        email: current_user.email,
        name: current_user.name,
        exp: 2.hours.from_now.to_i,
      },
      ENV['INTERCOM_IDENTITY_SECRET'],
      'HS256'
    )

    render json: { token: token }
  end
end
```

Adapt the example to the user's backend language and framework. The key requirements are:
- The endpoint is authenticated (only the logged-in user can get their own JWT)
- The secret comes from an environment variable, never hardcoded
- The token includes `user_id` and has a short expiration

## Step 2: Frontend — Boot Messenger with JWT

The frontend fetches the JWT from the backend and passes it to the Messenger via `intercom_user_jwt`.

### Basic JavaScript (No Framework)

Add before the closing `</body>` tag:

```html
<script>
  // Fetch JWT from your backend, then boot the Messenger
  fetch('/api/intercom-jwt', { credentials: 'include' })
    .then(res => res.json())
    .then(({ token }) => {
      window.Intercom('boot', {
        api_base: 'https://api-iam.intercom.io',
        app_id: 'YOUR_WORKSPACE_ID',
        intercom_user_jwt: token,
      });
    });
</script>
<script>
  (function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',w.intercomSettings);}else{var d=document;var i=function(){i.c(arguments);};i.q=[];i.c=function(args){i.q.push(args);};w.Intercom=i;var l=function(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/YOUR_WORKSPACE_ID';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);};if(document.readyState==='complete'){l();}else if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}}})();
</script>
```

### Anonymous Visitors

For pages where the visitor is not logged in (marketing pages, docs), boot without a JWT:

```javascript
window.Intercom('boot', {
  api_base: 'https://api-iam.intercom.io',
  app_id: 'YOUR_WORKSPACE_ID',
});
```

No JWT is needed for anonymous visitors. Intercom tracks them as leads.

## Framework-Specific Installation

If the user is using React, Next.js, Vue.js, or another SPA framework, refer to `references/framework-guides.md` for JWT-integrated installation code. Ask the user what framework they are using if it is not obvious from their codebase.

After reading the framework guide, adapt the code to the user's specific project structure — find their main layout component, app entry point, or equivalent, and integrate the Messenger there.

## Regional Data Centers

Intercom operates in multiple regions. The `api_base` URL must match the user's data residency region:

| Region | `api_base` URL |
|--------|----------------|
| US (default) | `https://api-iam.intercom.io` |
| EU (Ireland) | `https://api-iam.eu.intercom.io` |
| Australia | `https://api-iam.au.intercom.io` |

Ask the user which region their workspace is hosted in if they mention EU or Australian hosting, GDPR compliance, or data residency requirements. Default to US if unspecified.

## Security Best Practices

### Logout and Shutdown

When a user logs out, shut down the Messenger to clear session cookies and prevent data leakage:

```javascript
// Call this in your logout handler, BEFORE clearing session data
Intercom('shutdown');
```

After shutdown, re-initialize for the next user or as anonymous:

```javascript
Intercom('boot', {
  api_base: 'https://api-iam.intercom.io',
  app_id: 'YOUR_WORKSPACE_ID',
});
```

Always include the shutdown call. Skipping it leaks conversation data between users on shared devices.

### Protect Identifying Attributes

In Intercom (**Settings > Messenger > Security**), mark identifying attributes (email, phone, account IDs) as **protected**. This prevents client-side code from spoofing these values — only the server-signed JWT can set them.

### Token Expiration

Set short JWT expiration times. Two hours is a good default. When a token expires mid-session, Intercom automatically issues a fresh 1-hour cookie if the user is still active. Session duration defaults to 7 days but can be shortened via the `session_duration` attribute in the JWT.

To refresh an expired token, fetch a new JWT from your backend and re-boot the Messenger:

```javascript
function refreshIntercomToken() {
  fetch('/api/intercom-jwt', { credentials: 'include' })
    .then(res => res.json())
    .then(({ token }) => {
      window.Intercom('boot', {
        api_base: 'https://api-iam.intercom.io',
        app_id: 'YOUR_WORKSPACE_ID',
        intercom_user_jwt: token,
      });
    });
}
```

## Single-Page App (SPA) Route Changes

In SPAs where the page does not fully reload on navigation, notify the Messenger of route changes:

```javascript
// Call after each client-side route change
Intercom('update');
```

Where to place this depends on the routing library:

- **React Router** — In a `useEffect` hook that watches `location` changes
- **Next.js App Router** — In a layout component using `usePathname()`
- **Vue Router** — In a `router.afterEach()` navigation guard

Without this, the Messenger may show stale content or miss page-specific triggers.

## Installation Checklist

After generating the installation code, verify with the user:

1. The backend JWT endpoint exists and is authentication-protected
2. The Identity Verification Secret is stored as an environment variable (not hardcoded)
3. JWTs include `user_id` and have a short expiration (`exp`)
4. The frontend passes `intercom_user_jwt` when booting the Messenger
5. The Workspace ID and `api_base` are correct for their region
6. The logout flow calls `Intercom('shutdown')`
7. SPA route changes trigger `Intercom('update')`
8. Identifying attributes are marked as protected in Intercom settings

## Insecure Installation (Only If Explicitly Requested)

If the user explicitly asks for an "insecure installation" (no JWT, no identity verification), provide the basic snippet that passes user attributes directly in `intercomSettings` without server-side signing:

```html
<script>
  window.intercomSettings = {
    api_base: "https://api-iam.intercom.io",
    app_id: "YOUR_WORKSPACE_ID",
    name: "Jane Doe",
    email: "jane@example.com",
    created_at: 1312182000
  };
</script>
<script>
  (function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',w.intercomSettings);}else{var d=document;var i=function(){i.c(arguments);};i.q=[];i.c=function(args){i.q.push(args);};w.Intercom=i;var l=function(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/YOUR_WORKSPACE_ID';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);};if(document.readyState==='complete'){l();}else if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}}})();
</script>
```

Warn the user that this is insecure: anyone can impersonate any user by modifying the `email` or `name` values in the browser console. Recommend switching to JWT-based authentication for production use.
