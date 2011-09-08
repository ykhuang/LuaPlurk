--[[
	LuaPlurk:  A Lua implementation of Plurk OAuth
	Auther: ykhuang@gmail.com
	Version: 0.1
]]--

local modname = 'LuaPlurk'
local LuaPlurk = {}
_G[modname] = LuaPlurk
package.loaded[modname] = LuaPlurk
local _G = _G
setfenv(1,LuaPlurk)

LuaPlurk = { app_key = nil, app_secret = nil, oauth_token = nil, oauth_token_secret =nil, client = nil}
local oauth = _G.require "OAuth"

function init(key, secret)
  app_key = key
  app_secret = secret
  client = oauth.new(app_key, app_secret,
    { RequestToken='http://www.plurk.com/OAuth/request_token',
      AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
      AccessToken='http://www.plurk.com/OAuth/access_token'} )
  local values = client:RequestToken()
  return values.oauth_callback_confirmed, values.oauth_token, values.oauth_token_secret
end

-- todo: check if the access token has expired and return status
function init_client(key, secret, token_key, token_secret)
  app_key = key
  app_secret = secret
  client = oauth.new(app_key, app_secret,
    { RequestToken='http://www.plurk.com/OAuth/request_token',
      AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
      AccessToken='http://www.plurk.com/OAuth/access_token'
	}, {
		OAuthToken = token_key,
		OAuthTokenSecret = token_secret
	})
end

function getAuthorizedUrl(token)
  return client:BuildAuthorizationUrl({ oauth_token = token })
end

function getAccessToken(token, secret, verifier)
  client = oauth.new(app_key, app_secret,
    { RequestToken='http://www.plurk.com/OAuth/request_token',
      AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
      AccessToken='http://www.plurk.com/OAuth/access_token'
     }, {
      OAuthToken = token,
      OAuthVerifier = verifier
    })
  client:SetTokenSecret(secret)
  local values, err, headers, status, body = client:GetAccessToken()
  oauth_token = values.oauth_token
  oauth_token_secret = values.oauth_token_secret
  return oauth_token, oauth_token_secret
end

function plurkRequest(token, api, args)
	local api_url = 'http://www.plurk.com'..api
	if args == nil then
		args = {}
	end
	args['oauth_token'] = token
	return client:PerformRequest("POST", api_url, args)
end