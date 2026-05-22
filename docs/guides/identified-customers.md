# Identifying customers

By default the SDK treats every user as anonymous and maintains
continuity across app launches via a device-stable guest ID. That is
enough for most marketing sites. For products that already have their
own login system you can hand the SDK a stronger identity, so that
support agents see the user's email, name, and CRM linkage from the
first message.

There are two flavours of identification:

- **Identified, unverified** — you pass an `id`, `email`, and/or `name`
  but no proof. Agents see the information, but it can be spoofed by
  anyone reverse-engineering the client. Fine for low-risk contexts.
- **Identified, verified** — you additionally pass a `verificationHash`
  computed on **your server** using a shared secret. Agents see a
  `verified` badge on the conversation; impersonation requires the
  shared secret, which never leaves the server.

This guide covers both, with copy-paste recipes for the server side.

## Identified, unverified

```dart
await Chataptor.init(
  siteId: 'your-site-id',
  widgetKey: 'pk_your_widget_key',
  config: ChataptorConfig(
    siteId: 'your-site-id',
    widgetKey: 'pk_your_widget_key',
    customer: const CustomerIdentity(
      id: 'user-42',
      email: 'jane@example.com',
      name: 'Jane Doe',
    ),
  ),
);
```

`id` is whatever stable identifier you use internally (database PK,
auth subject, etc.). `email` and `name` show up in the agent UI.

## Identified, verified

The shared secret is your site's widget API secret — distinct from
the public widget key. You will find both in the Chataptor admin
console. Never embed the secret in client code; compute the hash on
your server, then send the result down to the client.

The hash is:

```
HMAC-SHA256(message = email, key = widget_api_secret)
```

…hex-encoded, lowercase.

Pass the result as `verificationHash`:

```dart
customer: CustomerIdentity(
  id: 'user-42',
  email: 'jane@example.com',
  name: 'Jane Doe',
  verificationHash: hashFromYourServer, // computed below
),
```

### Server-side recipes

#### Elixir / Phoenix

```elixir
hash =
  :crypto.mac(:hmac, :sha256, widget_api_secret, user.email)
  |> Base.encode16(case: :lower)
```

#### Ruby / Rails

```ruby
require 'openssl'

hash = OpenSSL::HMAC.hexdigest('SHA256', widget_api_secret, user.email)
```

#### Node.js

```js
import { createHmac } from 'node:crypto';

const hash = createHmac('sha256', widgetApiSecret)
  .update(user.email)
  .digest('hex');
```

#### PHP

```php
$hash = hash_hmac('sha256', $user->email, $widgetApiSecret);
```

#### Python

```python
import hmac
import hashlib

hash = hmac.new(
    widget_api_secret.encode('utf-8'),
    user.email.encode('utf-8'),
    hashlib.sha256,
).hexdigest()
```

### Verifying your setup

Once your server-side HMAC is wired up and the SDK is configured with
the resulting `verificationHash`, your agents will see a verified
badge on the customer's conversation. If the badge does not appear,
re-check the recipe — the usual suspects are a mismatched secret, the
wrong value being hashed, or the hex being uppercased.

## When to identify

- **Before opening the chat screen the first time.** This is the
  simplest path — pass `CustomerIdentity` into `Chataptor.init` and the
  user opens the chat already identified.
- **After login, mid-session.** v0.2.0 adds `Chataptor.instance.identify()`
  to migrate an anonymous session to an identified one on the fly. The
  prior anonymous conversation history follows the customer over.

## See also

- [Getting started](./getting-started.md)
- [Architecture decisions](../../ARCHITECTURE.md) — decision #13
  documents the three identification modes.
