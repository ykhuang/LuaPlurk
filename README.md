# LuaPlurk #
This is a Plurk API 2.0 implementation based on Lua. Ignacia's LuaOAuth is used to do the OAuth1.0 part.

## Lua packages dependencies #

Lua 5.1.4
LuaOAuth by Ignacio: https://github.com/ignacio/LuaOAuth

LuaOAuth support async and sync mode. Only synchrous mode is support so far.

LuaOAuth depends on several packages:
luacrypto
LuaSocket
LuaNode by Ignacio (for async mode)

## Usage and examples #

To request token:
``` lua
-- get request token
local ret, rtoken, rtoken_secret = papi.init(app_key, app_secret)
local aurl = papi.getAuthorizedUrl(rtoken)
-- Prompt user to authorize
print("Enter PIN verifier:")
local verifier = assert(io.read("*n"))
verifier = tostring(verifier)
local access_token, access_token_secret = papi.getAccessToken(rtoken, rtoken_secret, verifier)
```

To access Plurk API
``` lua
-- use init_client if you already has access token
papi.init_client(app_key, app_secret, token, token_secret)
local api_url = '/APP/Profile/getPublicProfile'
local api_args = {user_id='whoever'}
local response_code, response_headers, response_status_line, response_body =
	papi.plurkRequest(token, api_url, api_args)
```

## Reference #


## Changelog #
2011, Sep. 8: Upload first LuaPlurk and goes v0.1.


## Todo #
* Add token expiration check.
