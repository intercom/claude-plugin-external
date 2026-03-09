---
name: install-messenger
license: MIT
description: >
  Install the Intercom Messenger on a website or web application with
  secure JWT-based identity verification. Generates backend and frontend
  code for React, Next.js, Vue.js, Angular, Ember, and plain JavaScript.
  Supports Node.js, Python (Flask/Django), PHP, and Ruby backends. Use when
  the user asks to "install Intercom", "add the Intercom Messenger", "set up
  Intercom chat widget", "add customer chat to my website", or "integrate Intercom".
disable-model-invocation: true
argument-hint: "[framework]"
---

# Install Intercom Messenger

Help the user install the Intercom Messenger on their website or application with JWT-based identity verification. This is the secure default — it prevents user impersonation by cryptographically signing user identity on the server.

Only use the insecure (non-JWT) installation if the user explicitly asks for an "insecure installation". Never default to it.

## Requirements

Gather these from the user before proceeding:

1. **Workspace ID** (also called App ID) — A short alphanumeric string like `abc12345`.
   - Found on the [Intercom Messenger install page](https://app.intercom.com/a/apps/_/settings/channels/messenger/install)
   - Or in the URL bar: `https://app.intercom.com/a/apps/<workspace_id>/...`

2. **Identity Verification Secret** (also called Messenger API Secret) — Found on the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security). This is the HMAC secret used to sign JWTs. It must never appear in frontend code.

Ask the user for both values. Do not proceed without the Workspace ID. If they don't have the Identity Verification Secret yet, direct them to the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security) to enable it.

In all generated code, replace `YOUR_WORKSPACE_ID` with the user's actual Workspace ID. Do not leave placeholders — substitute the real values they provided.

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

### Python / Django Example

```python
# views.py
import jwt
import time
import os
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required

INTERCOM_SECRET = os.environ['INTERCOM_IDENTITY_SECRET']

@login_required
def intercom_jwt(request):
    token = jwt.encode(
        {
            'user_id': str(request.user.id),
            'email': request.user.email,
            'name': request.user.get_full_name(),
            'exp': int(time.time()) + 7200,  # 2 hours
        },
        INTERCOM_SECRET,
        algorithm='HS256',
    )
    return JsonResponse({'token': token})
```

Add the URL pattern: `path('api/intercom-jwt', views.intercom_jwt)` in your `urls.py`.

### PHP Example

Requires the `firebase/php-jwt` package: `composer require firebase/php-jwt`

```php
<?php
// api/intercom-jwt.php
require_once 'vendor/autoload.php';
use Firebase\JWT\JWT;

$secret = getenv('INTERCOM_IDENTITY_SECRET');
$user = get_authenticated_user(); // Your auth logic

$token = JWT::encode([
    'user_id' => (string) $user->id,
    'email' => $user->email,
    'name' => $user->name,
    'exp' => time() + 7200, // 2 hours
], $secret, 'HS256');

header('Content-Type: application/json');
echo json_encode(['token' => $token]);
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

**Alternative: `intercom-rails` gem** — For simpler setups, Intercom provides a Rails gem that auto-injects the Messenger. Install with `gem "intercom-rails"`, run `rails generate intercom:config YOUR_WORKSPACE_ID`, and configure the secret in the generated initializer. See the [Intercom install page](https://app.intercom.com/a/apps/_/settings/channels/messenger/install) for details. The JWT approach above gives you more control and works with any Ruby backend, not just Rails.

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
  app_id: 'YOUR_WORKSPACE_ID',
});
```

No JWT is needed for anonymous visitors. Intercom tracks them as leads.

## Framework-Specific Installation

If the user is using React, Next.js, Vue.js, Angular, Ember, or another SPA framework, refer to `references/framework-guides.md` for JWT-integrated installation code. Ask the user what framework they are using if it is not obvious from their codebase.

After reading the framework guide, adapt the code to the user's specific project structure — find their main layout component, app entry point, or equivalent, and integrate the Messenger there.

## Regional Data Centers

Most Intercom workspaces are in the US region, which is the default — no `api_base` is needed. Only add `api_base` if the user's workspace is hosted in EU or Australia:

| Region | `api_base` | Required? |
|--------|------------|-----------|
| US (default) | *(not needed)* | No |
| EU (Ireland) | `https://api-iam.eu.intercom.io` | Yes |
| Australia | `https://api-iam.au.intercom.io` | Yes |

If the user mentions EU or Australian hosting, GDPR compliance, or data residency requirements, add the appropriate `api_base` to every `Intercom('boot', ...)` call. Otherwise, omit it.

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
  app_id: 'YOUR_WORKSPACE_ID',
});
```

Always include the shutdown call. Skipping it leaks conversation data between users on shared devices.

### Protect Identifying Attributes

On the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security), mark identifying attributes (email, phone, account IDs) as **protected**. This prevents client-side code from spoofing these values — only the server-signed JWT can set them.

### Token Expiration

Set short JWT expiration times. Two hours is a good default. When a token expires mid-session, Intercom automatically issues a fresh 1-hour cookie if the user is still active. Session duration defaults to 7 days but can be shortened via the `session_duration` attribute in the JWT.

To refresh an expired token, fetch a new JWT from your backend and re-boot the Messenger:

```javascript
function refreshIntercomToken() {
  fetch('/api/intercom-jwt', { credentials: 'include' })
    .then(res => res.json())
    .then(({ token }) => {
      window.Intercom('boot', {
        app_id: 'YOUR_WORKSPACE_ID',
        intercom_user_jwt: token,
      });
    });
}
```

## Troubleshooting

### JWT Library Not Installed
Error: `Cannot find module 'jsonwebtoken'` (Node.js), `ModuleNotFoundError: No module named 'jwt'` (Python), or `LoadError: cannot load such file -- jwt` (Ruby)
Solution: Install the JWT library for the user's language — `npm install jsonwebtoken`, `pip install PyJWT`, or `gem install jwt`.

### Wrong Identity Verification Secret
Symptom: Messenger loads but shows "Identity verification failed" or user attributes don't appear.
Cause: The secret used to sign JWTs doesn't match the workspace's Identity Verification Secret.
Solution: Verify the secret on the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security). Ensure the environment variable holds the correct value for this workspace.

### Plan Doesn't Support Identity Verification
Symptom: Identity Verification Secret not available in Intercom settings.
Cause: Identity verification is a paid feature not available on all Intercom plans.
Solution: Check the workspace's Intercom plan on the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security). If identity verification is unavailable, the user may need to upgrade or use the insecure installation (with explicit acknowledgment of the security trade-off).

### JWT `exp` in the Past
Symptom: Messenger rejects the token immediately after creation.
Cause: Server clock is wrong or `exp` calculation is incorrect.
Solution: Check the server's system time (`date` command). Ensure NTP is configured. Verify the `exp` value is a future Unix timestamp in seconds (not milliseconds).

### CORS Errors on JWT Endpoint
Symptom: Browser console shows `Access-Control-Allow-Origin` errors when fetching the JWT.
Cause: The backend JWT endpoint doesn't allow requests from the frontend's origin.
Solution: Configure CORS on the JWT endpoint to allow the frontend origin. For Express: `cors({ origin: 'https://your-app.com', credentials: true })`. For other frameworks, add the appropriate CORS headers.

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
- **Angular Router** — In a service subscribing to `NavigationEnd` events
- **Ember Router** — In an instance initializer listening to `routeDidChange`

Without this, the Messenger may show stale content or miss page-specific triggers.

## Third-Party Integrations

Intercom also supports installation via these platforms. These don't require writing code — configure them through each platform's UI:

- **WordPress** — Install the official Intercom plugin from the WordPress plugin directory
- **Shopify** — Install via the Shopify App Store
- **Google Tag Manager** — Add the Intercom tag using the GTM template gallery
- **Segment** — Enable the Intercom destination in your Segment workspace

For setup instructions, direct users to the [Messenger install page](https://app.intercom.com/a/apps/_/settings/channels/messenger/install).

## Verifying the Installation

After generating the code, verify the installation before considering the task complete. If you have browser automation tools available (e.g., Playwright MCP, playwright-cli, or similar), use them to programmatically verify. Otherwise, tell the user how to verify manually.

### Automated Verification with Browser Automation

If browser automation tools are available (e.g., Playwright MCP, playwright-cli, or similar), run the app and verify:

1. **Navigate to a public page** and check:
   - `typeof window.Intercom === 'function'` — the Intercom stub is initialized
   - A `<script>` tag with `src` containing `widget.intercom.io/widget/WORKSPACE_ID` exists in the DOM
   - The boot call was queued with the correct `app_id` (check `window.Intercom.q`)

2. **Log in as a test user**, then check:
   - The JWT endpoint returns HTTP 200 with a `{ "token": "..." }` response
   - The boot call includes `intercom_user_jwt` with the signed token

3. **Note:** The Intercom widget bubble (iframe) loads from an external CDN (`widget.intercom.io`). In headless or sandboxed browser environments, the CDN may be unreachable — the widget script will fail to load and no iframe will appear. This is a network restriction of the test environment, not a code problem. If the stub function, script tag, JWT endpoint, and boot calls all check out, the installation is correct.

### Automated Verification with Intercom MCP

If the Intercom MCP tools are available (e.g., `search_contacts`), verify that a logged-in user's identity was created in Intercom after they loaded the Messenger:

1. Have the user log in to the app (or use a test account) and load a page with the Messenger
2. Use `search_contacts` to search for the user by name or `external_id` matching the `user_id` from the JWT
3. Confirm the contact exists with `role: "user"` (not `"lead"`) and the correct `external_id` — this proves the JWT was accepted and Intercom created a verified user record

This is the strongest verification available — it confirms the full chain from JWT signing to Intercom identity creation.

### Manual Verification

Instruct the user to verify by:

1. Start the app and open it in a browser
2. Confirm the Intercom Messenger bubble appears in the bottom-right corner of the page
3. Log in to the app and confirm the Messenger bubble still appears
4. Click the Messenger bubble and send a test message
5. Go to the [Intercom Inbox](https://app.intercom.com/a/inbox/_/inbox/) and confirm the test conversation appears, attributed to the correct user name and identity

## Installation Checklist

After generating the installation code, verify with the user:

1. The backend JWT endpoint exists and is authentication-protected
2. The Identity Verification Secret is stored as an environment variable (not hardcoded)
3. JWTs include `user_id` and have a short expiration (`exp`)
4. The frontend passes `intercom_user_jwt` when booting the Messenger
5. The Workspace ID is correct (and `api_base` is set if the workspace is in EU or Australia)
6. The logout flow calls `Intercom('shutdown')`
7. SPA route changes trigger `Intercom('update')`

## Post-Installation: Enforce JWT Authentication

After the code is deployed, the user must enable and enforce identity verification in Intercom. Direct them to complete these steps:

1. Go to the [Messenger Security page](https://app.intercom.com/a/apps/_/settings/channels/messenger/security)
2. **Enable Identity Verification** if not already enabled — this activates JWT-based authentication for the Messenger
3. **Enforce Identity Verification** — once enabled and confirmed working, switch to "Enforced" mode so that unauthenticated Messenger sessions are rejected
4. **Mark identifying attributes as protected** — on the same page, mark attributes like email, phone, and account IDs as protected so only server-signed JWTs can set them

This is a critical step. Without enforcement, the JWT signing is optional and users can still be impersonated via the browser console. Enforcement ensures only server-signed identities are accepted.

## Insecure Installation (Only If Explicitly Requested)

If the user explicitly asks for an "insecure installation" (no JWT, no identity verification), provide the basic snippet that passes user attributes directly in `intercomSettings` without server-side signing:

```html
<script>
  window.intercomSettings = {
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
