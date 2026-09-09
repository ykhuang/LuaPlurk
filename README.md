# LuaPlurk

LuaPlurk is a Lua client for the Plurk API 2.0. It uses HTTPS and OAuth 1.0a
for authorization. “API 2.0” is the Plurk API version; it does not mean OAuth
2.0.

## Supported features

- Lua 5.1 and 5.4 on Linux and macOS; Lua 5.4 is recommended.
- HTTPS-only OAuth 1.0a request-token, authorization URL, and access-token
  flows.
- HMAC-SHA1 request signing through the HTTP `Authorization` header.
- Generic signed `GET` and `POST` requests to documented `/APP/` paths.
- JSON response decoding and structured errors.
- OAuth utility calls: `checkToken`, `checkTime`, and `echo`.
- Configurable timeouts and certificate verification using the system CA trust
  store.

## Installation

Install Lua, LuaRocks, OpenSSL development headers, and the project
dependencies. On Debian/Ubuntu:

```sh
sudo apt update
sudo apt install -y lua5.4 liblua5.4-dev luarocks libssl-dev build-essential pkg-config

cd /path/to/LuaPlurk
luarocks --lua-version=5.4 install --only-deps luaplurk-0.1.0-1.rockspec
```

LuaPlurk requires LuaSec, LuaSocket, luaossl, and dkjson. TLS certificate
verification is mandatory; do not disable it.

## OAuth login

Create a Plurk application to obtain an app key and app secret. Keep app
secrets, access tokens, and token secrets out of source control and shared
logs.

```lua
local plurk = require("LuaPlurk")

local client, err = plurk.new({
  app_key = assert(os.getenv("PLURK_APP_KEY")),
  app_secret = assert(os.getenv("PLURK_APP_SECRET")),
  timeout_seconds = 30,
})
assert(client, err and err.message)

local request_token, request_err = client:request_token("oob")
assert(request_token, request_err and request_err.message)

local url, url_err = client:authorization_url(request_token.oauth_token)
assert(url, url_err and url_err.message)
print("Open this URL, authorize the app, then enter the verifier:")
print(url)

local verifier = assert(io.read())
local credentials, access_err = client:access_token(
  request_token.oauth_token,
  request_token.oauth_token_secret,
  verifier
)
assert(credentials, access_err and access_err.message)

-- Store credentials.oauth_token and credentials.oauth_token_secret securely.
```

An interactive helper is also included:

```sh
lua5.4 scripts/oauth_test.lua
```

It reads `PLURK_APP_KEY` and `PLURK_APP_SECRET` from the environment.

## Use an existing access token

```lua
local plurk = require("LuaPlurk")

local client, err = plurk.new({
  app_key = assert(os.getenv("PLURK_APP_KEY")),
  app_secret = assert(os.getenv("PLURK_APP_SECRET")),
  access_token = assert(os.getenv("PLURK_ACCESS_TOKEN")),
  access_token_secret = assert(os.getenv("PLURK_ACCESS_TOKEN_SECRET")),
})
assert(client, err and err.message)

local token_info, token_err = client:oauth_utils():check_token()
assert(token_info, token_err and token_err.message)
print("Authorized user ID: " .. tostring(token_info.user_id))

local profile, profile_err = client:request("GET", "/APP/Profile/getOwnProfile", {})
assert(profile, profile_err and profile_err.message)
print("Display name: " .. tostring(profile.display_name))
```

`client:request(method, path, params)` accepts `GET` and `POST` for `/APP/`
paths. It signs each request, uses HTTPS, and decodes successful JSON
responses.

## Errors

Every operation returns either `result, nil` or `nil, error`.

```lua
{
  kind = "transport" | "oauth" | "http" | "api" | "decode" | "validation",
  message = "human-readable summary",
  retryable = false,
  request_id = "local-correlation-id",
  status = 401,       -- when available
  api_error = "...", -- when provided by Plurk
}
```

Requests are never retried automatically. Applications must make their own
deliberate decision before retrying a failed write operation.

## Testing

Run the offline suite:

```sh
LUA_BIN=lua5.4 ./scripts/run-tests.sh
```

To validate an existing authorization against Plurk, provide credentials as
environment variables and run:

```sh
PLURK_TEST_APP_KEY=... PLURK_TEST_APP_SECRET=... \
PLURK_TEST_ACCESS_TOKEN=... PLURK_TEST_ACCESS_TOKEN_SECRET=... \
lua5.4 test/live_check_token.lua
```

This performs `checkToken`, `checkTime`, and `echo`. Do not use tokens from an
account you care about for expiry or write-operation testing.

## Legacy module API

`init`, `init_client`, `getAuthorizedUrl`, `getAccessToken`, and
`plurkRequest` remain as deprecated compatibility wrappers. New applications
should create a client with `LuaPlurk.new()`.

## Security

- Do not commit or share app secrets, access tokens, or token secrets.
- Revoke and replace any token that is accidentally disclosed.
- Use HTTPS only; certificate verification is intentionally mandatory.
- Report security concerns privately to the project maintainer.
