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

Help the user install the Intercom Messenger on their website or application. Determine their framework, gather the required configuration, and provide the correct installation code.

## Requirements

Before starting, you need the user's **Workspace ID** (also called App ID). This is a short alphanumeric string like `abc12345`.

Where to find it:
- In Intercom: **Settings > Installation > Web** — the Workspace ID is shown in the code snippet
- In the URL bar when logged into Intercom: `https://app.intercom.com/a/apps/<workspace_id>/...`
- Via the Intercom API: the `app.id` field in the `/me` endpoint response

Ask the user for their Workspace ID if they haven't provided it. Do not proceed without it.

## Basic JavaScript Installation

For plain HTML sites or when no framework is in use, add this snippet before the closing `</body>` tag.

### Logged-in Users (Identified)

Use this when the visitor is an authenticated user in your app. Pass their details so conversations are tied to their Intercom contact record:

```html
<script>
  window.intercomSettings = {
    api_base: "https://api-iam.intercom.io",
    app_id: "YOUR_WORKSPACE_ID",
    name: "Jane Doe",           // Full name of the logged-in user
    email: "jane@example.com",  // Email address
    created_at: 1312182000      // Unix timestamp of user sign-up date
  };
</script>
<script>
  (function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',w.intercomSettings);}else{var d=document;var i=function(){i.c(arguments);};i.q=[];i.c=function(args){i.q.push(args);};w.Intercom=i;var l=function(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/YOUR_WORKSPACE_ID';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);};if(document.readyState==='complete'){l();}else if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}}})();
</script>
```

### Anonymous Visitors

Use this when the visitor is not logged in. Intercom will track them as a lead:

```html
<script>
  window.intercomSettings = {
    api_base: "https://api-iam.intercom.io",
    app_id: "YOUR_WORKSPACE_ID"
  };
</script>
<script>
  (function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',w.intercomSettings);}else{var d=document;var i=function(){i.c(arguments);};i.q=[];i.c=function(args){i.q.push(args);};w.Intercom=i;var l=function(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/YOUR_WORKSPACE_ID';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);};if(document.readyState==='complete'){l();}else if(w.attachEvent){w.attachEvent('onload',l);}else{w.addEventListener('load',l,false);}}})();
</script>
```

Replace `YOUR_WORKSPACE_ID` with the user's actual Workspace ID in all snippets.

## Framework-Specific Installation

If the user is using React, Next.js, Vue.js, or another SPA framework, refer to the detailed guides in `references/framework-guides.md` for the correct installation approach. Ask the user what framework they are using if it is not obvious from their codebase.

After reading the framework guide, adapt the code to the user's specific project structure — find their main layout component, app entry point, or equivalent, and integrate the Messenger there.

## Regional Data Centers

Intercom operates in multiple regions. The `api_base` URL must match the user's data residency region:

| Region | `api_base` URL |
|--------|----------------|
| US (default) | `https://api-iam.intercom.io` |
| EU (Ireland) | `https://api-iam.eu.intercom.io` |
| Australia | `https://api-iam.au.intercom.io` |

Ask the user which region their workspace is hosted in if they mention EU or Australian hosting, GDPR compliance, or data residency requirements. Default to US if unspecified.

## Security: Logout and Shutdown

When a user logs out of the host application, shut down the Intercom Messenger to prevent the next user on the same device from seeing the previous user's conversations:

```javascript
// Call this in your logout handler, BEFORE clearing session data
Intercom('shutdown');
```

After shutdown, re-initialize Intercom for the new user or as anonymous:

```javascript
// After logout + shutdown, boot for the next user or as anonymous
Intercom('boot', {
  api_base: "https://api-iam.intercom.io",
  app_id: "YOUR_WORKSPACE_ID"
});
```

Always include the shutdown call in the user's logout flow. This is a security requirement — skipping it leaks conversation data between users on shared devices.

## Single-Page App (SPA) Route Changes

In SPAs where the page does not fully reload on navigation, the Messenger needs to be notified of route changes so it can update its state and show relevant messages:

```javascript
// Call this after each client-side route change
Intercom('update');
```

Where to place this depends on the routing library:

- **React Router** — In a `useEffect` hook that watches `location` changes
- **Next.js App Router** — In a layout component using `usePathname()`
- **Vue Router** — In a `router.afterEach()` navigation guard

If the user's app is an SPA, always include the route-change update. Without it, the Messenger may show stale content or miss page-specific triggers.

## Installation Checklist

After generating the installation code, verify with the user:

1. The Workspace ID is correctly placed in all snippets
2. The `api_base` matches their data region
3. Identified users pass at minimum `email` (and ideally `name` and `created_at`)
4. The logout flow includes `Intercom('shutdown')`
5. SPA route changes trigger `Intercom('update')`
6. The snippet loads on all pages where the Messenger should appear
