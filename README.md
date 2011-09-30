# LuaPlurk #
This is a Plurk OAuth implementation based on Lua. Ignacia's LuaOAuth is used to do the OAuth1.0 part.

## Lua packages dependencies #

Lua 5.1.4

LuaOAuth by Ignacio: https://github.com/ignacio/LuaOAuth

LuaOAuth supports two modes of operation: 
"synchronous" and "asynchronous" mode. So far LuaPlurk support only synchronous mode.
Check out LuaOAuth for more package dependencies.

## Usage and examples #

To request token:

``` lua
papi = require "LuaPlurk"
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
	papi.plurkRequest(api_url, api_args)
```

## Reference #

Plurk API: http://www.plurk.com/API

LuaOAuth: https://github.com/ignacio/LuaOAuth

dkjson by David Kolf, (The JSON4Lua cannot decode empty '[]' in json string.)
http://chiselapp.com/user/dhkolf/repository/dkjson/home

## Changelog #
2011, Sep. 8: Upload first LuaPlurk and go V0.1.


## Todo #
* Add token expiration check.
* Verify LuaPlurk on each API.
	- Complete: Profile, Cliques, FriendsFans, Timeline(except UploadPicture), Alerts
	
## Known issues #
* /APP/Timeline/uploadPicture not work since LuaOAuth does not support multipart/form-data.
