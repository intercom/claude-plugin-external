# Framework-Specific Messenger Installation Guides

Detailed installation instructions for integrating the Intercom Messenger with popular frontend frameworks.

## React via `@intercom/messenger-js-sdk`

The official Intercom React SDK provides a clean, hook-based integration.

### Installation

```bash
npm install @intercom/messenger-js-sdk
# or
yarn add @intercom/messenger-js-sdk
```

### Basic Setup

Initialize the Messenger in your app's root component or layout:

```tsx
import Intercom from '@intercom/messenger-js-sdk';

function App() {
  Intercom({
    app_id: 'YOUR_WORKSPACE_ID',
  });

  return <div>{/* Your app content */}</div>;
}
```

### Identified Users

Pass user attributes when the user is authenticated:

```tsx
import Intercom from '@intercom/messenger-js-sdk';

function App({ user }) {
  Intercom({
    app_id: 'YOUR_WORKSPACE_ID',
    user_id: user.id,
    name: user.name,
    email: user.email,
    created_at: user.createdAt, // Unix timestamp
  });

  return <div>{/* Your app content */}</div>;
}
```

### Shutdown on Logout

```tsx
import { shutdown } from '@intercom/messenger-js-sdk';

function LogoutButton() {
  const handleLogout = () => {
    shutdown();          // Clear Intercom session first
    // ... your logout logic
  };

  return <button onClick={handleLogout}>Log out</button>;
}
```

### Route Change Updates

With React Router v6+:

```tsx
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { update } from '@intercom/messenger-js-sdk';

function IntercomRouteUpdater() {
  const location = useLocation();

  useEffect(() => {
    update();
  }, [location]);

  return null;
}

// Add <IntercomRouteUpdater /> inside your <Router>
```

---

## Next.js with `next/script`

For Next.js applications, use the `next/script` component for optimized script loading.

### App Router (Next.js 13+)

Create a client component for the Messenger:

```tsx
// components/IntercomMessenger.tsx
'use client';

import Script from 'next/script';
import { usePathname } from 'next/navigation';
import { useEffect } from 'react';

interface IntercomMessengerProps {
  appId: string;
  user?: {
    name: string;
    email: string;
    createdAt: number;
  };
}

export function IntercomMessenger({ appId, user }: IntercomMessengerProps) {
  const pathname = usePathname();

  // Update Intercom on route changes
  useEffect(() => {
    if (window.Intercom) {
      window.Intercom('update');
    }
  }, [pathname]);

  const intercomSettings = {
    api_base: 'https://api-iam.intercom.io',
    app_id: appId,
    ...(user && {
      name: user.name,
      email: user.email,
      created_at: user.createdAt,
    }),
  };

  return (
    <>
      <Script
        id="intercom-settings"
        strategy="lazyOnload"
        dangerouslySetInnerHTML={{
          __html: `window.intercomSettings = ${JSON.stringify(intercomSettings)};`,
        }}
      />
      <Script
        id="intercom-widget"
        strategy="lazyOnload"
        dangerouslySetInnerHTML={{
          __html: `(function(){var w=window;var ic=w.Intercom;if(typeof ic==="function"){ic('reattach_activator');ic('update',w.intercomSettings);}else{var d=document;var i=function(){i.c(arguments);};i.q=[];i.c=function(args){i.q.push(args);};w.Intercom=i;var l=function(){var s=d.createElement('script');s.type='text/javascript';s.async=true;s.src='https://widget.intercom.io/widget/${appId}';var x=d.getElementsByTagName('script')[0];x.parentNode.insertBefore(s,x);};if(document.readyState==='complete'){l();}else{w.addEventListener('load',l,false);}}})();`,
        }}
      />
    </>
  );
}
```

Add to your root layout:

```tsx
// app/layout.tsx
import { IntercomMessenger } from '@/components/IntercomMessenger';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <IntercomMessenger appId="YOUR_WORKSPACE_ID" />
      </body>
    </html>
  );
}
```

### Pages Router

For the Pages Router, add the Messenger in `_app.tsx`:

```tsx
// pages/_app.tsx
import Script from 'next/script';
import { useRouter } from 'next/router';
import { useEffect } from 'react';

export default function App({ Component, pageProps }) {
  const router = useRouter();

  useEffect(() => {
    const handleRouteChange = () => {
      if (window.Intercom) {
        window.Intercom('update');
      }
    };
    router.events.on('routeChangeComplete', handleRouteChange);
    return () => router.events.off('routeChangeComplete', handleRouteChange);
  }, [router]);

  return (
    <>
      <Component {...pageProps} />
      <Script
        id="intercom-settings"
        strategy="lazyOnload"
        dangerouslySetInnerHTML={{
          __html: `window.intercomSettings = { api_base: "https://api-iam.intercom.io", app_id: "YOUR_WORKSPACE_ID" };`,
        }}
      />
      <Script
        id="intercom-widget"
        strategy="lazyOnload"
        src="https://widget.intercom.io/widget/YOUR_WORKSPACE_ID"
      />
    </>
  );
}
```

---

## Vue.js Integration

### Vue 3 with Composition API

Create a composable for Intercom:

```typescript
// composables/useIntercom.ts
import { onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';

interface IntercomUser {
  name?: string;
  email?: string;
  created_at?: number;
}

export function useIntercom(appId: string, user?: IntercomUser) {
  const route = useRoute();

  onMounted(() => {
    window.intercomSettings = {
      api_base: 'https://api-iam.intercom.io',
      app_id: appId,
      ...user,
    };

    // Load the Intercom widget script
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://widget.intercom.io/widget/${appId}`;
    document.head.appendChild(script);
  });

  // Update on route changes
  watch(
    () => route.path,
    () => {
      if (window.Intercom) {
        window.Intercom('update');
      }
    }
  );
}

export function shutdownIntercom() {
  if (window.Intercom) {
    window.Intercom('shutdown');
  }
}
```

Use in your App component:

```vue
<!-- App.vue -->
<script setup lang="ts">
import { useIntercom } from './composables/useIntercom';

useIntercom('YOUR_WORKSPACE_ID', {
  name: 'Jane Doe',
  email: 'jane@example.com',
});
</script>

<template>
  <RouterView />
</template>
```

### Vue Router Navigation Guard

Alternatively, add route updates globally via a navigation guard:

```typescript
// router/index.ts
const router = createRouter({ /* ... */ });

router.afterEach(() => {
  if (window.Intercom) {
    window.Intercom('update');
  }
});
```

---

## Single-Page App Considerations

Regardless of framework, all SPAs share these concerns:

### Script Loading
The Intercom widget script should load once and persist across route changes. Do not re-insert the `<script>` tag on navigation — use `Intercom('update')` instead.

### Identity Changes
When a user logs in or switches accounts within the SPA:

```javascript
// 1. Shut down the current session
Intercom('shutdown');

// 2. Boot with the new user's identity
Intercom('boot', {
  api_base: 'https://api-iam.intercom.io',
  app_id: 'YOUR_WORKSPACE_ID',
  user_id: newUser.id,
  name: newUser.name,
  email: newUser.email,
});
```

### Content Security Policy (CSP)
If the application uses a strict CSP, add these directives:

```
script-src: https://widget.intercom.io https://js.intercomcdn.com
frame-src: https://intercom-sheets.com https://www.intercom-reporting.com
connect-src: https://api-iam.intercom.io https://nexus-websocket-a.intercom.io wss://nexus-websocket-a.intercom.io
img-src: https://static.intercomassets.com https://downloads.intercomcdn.com
font-src: https://js.intercomcdn.com
media-src: https://js.intercomcdn.com
```

### TypeScript Declarations
For TypeScript projects, add type declarations for the global `Intercom` function:

```typescript
// types/intercom.d.ts
interface IntercomSettings {
  api_base?: string;
  app_id: string;
  name?: string;
  email?: string;
  user_id?: string;
  created_at?: number;
  [key: string]: unknown;
}

interface Window {
  Intercom: (command: string, ...args: unknown[]) => void;
  intercomSettings: IntercomSettings;
}
```
