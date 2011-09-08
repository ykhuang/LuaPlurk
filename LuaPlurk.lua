---
-- Created by IntelliJ IDEA.
-- User: ying-kai.huang
-- Date: 2011/9/7
-- Time: 上午 11:59
-- To change this template use File | Settings | File Templates.
--
local modname = 'LuaPlurk'
local LuaPlurk = {}
_G[modname] = LuaPlurk
package.loaded[modname] = LuaPlurk
local _G = _G
setfenv(1,LuaPlurk)

LuaPlurk = { app_key = nil, app_secret = nil, oauth_token = nil, oauth_token_secret =nil, auth_url = nil, client = nil}
local oauth = _G.require "OAuth"


function check()
  _G.print("Check app_key:"..app_key)
end

function init(key, secret)
  app_key = key
  app_secret = secret
  client = oauth.new(app_key, app_secret,
    { RequestToken='http://www.plurk.com/OAuth/request_token',
      AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
      AccessToken='http://www.plurk.com/OAuth/access_token'} )
  local values = client:RequestToken()
  --_G.print(values.oauth_callback_confirmed)
  return values.oauth_callback_confirmed, values.oauth_token, values.oauth_token_secret
end

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
  -- _G.print("Build URL from token: "..token_key.." with client: "..app_key)
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

function plurkRequest(api, token)
--[[
  client = oauth.new(app_key, app_secret,
    { RequestToken='http://www.plurk.com/OAuth/request_token',
      AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
      AccessToken='http://www.plurk.com/OAuth/access_token'
    })
	]]--
	local api_url = 'http://www.plurk.com'..api
	_G.print("Get "..api_url.." with client "..app_key)

	local response_code, response_headers, response_status_line, response_body =
		client:PerformRequest("POST", api_url, {oauth_token = token})
	_G.print("response_code", response_code)
	_G.print("response_status_line", response_status_line)
	for k,v in _G.pairs(response_headers) do _G.print(k,v) end
	_G.print("response_body", response_body)
	
end