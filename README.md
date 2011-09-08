# LuaPlurk #
This is a Plurk OAuth implementation based on Lua. Ignacia's LuaOAuth is used to do the OAuth1.0 part.

## Lua packages dependencies #

Lua 5.1.4

LuaOAuth by Ignacio: https://github.com/ignacio/LuaOAuth

LuaOAuth support async and sync mode. LuaOAuth supports two modes of operation: 
"synchronous" and "asynchronous" mode. Only synchrous mode is support so far.
Check out LuaOAuth for more package dependencies.

## Usage and examples #

To request token:

``` lua
local ret, rtoken, rtoken_secret = papi.init(app_key, app_secret)
local aurl = papi.getAuthorizedUrl(rtoken)
```

Prompt user to authorize

``` lua
print("Enter PIN verifier:")
local verifier = assert(io.read("*n"))
verifier = tostring(verifier)
local access_token, access_token_secret = papi.getAccessToken(rtoken, rtoken_secret, verifier)
```

To access Plurk API, use init_client if you already has access token

``` lua
papi.init_client(app_key, app_secret, token, token_secret)
local api_url = '/APP/Profile/getPublicProfile'
local api_args = {user_id='whoever'}
local response_code, response_headers, response_status_line, response_body =
	papi.plurkRequest(token, api_url, api_args)
```

## Reference #

Plurk API: http://www.plurk.com/API

LuaOAuth: https://github.com/ignacio/LuaOAuth

## Changelog #
2011, Sep. 8: Upload first LuaPlurk and goes V0.1.


## Todo #
* Add token expiration check.
