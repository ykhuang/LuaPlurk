---
-- Created by IntelliJ IDEA.
-- User: ying-kai.huang
-- Date: 2011/9/1
-- Time: ¤U¤È 5:35
-- To change this template use File | Settings | File Templates.
--

key = 'TlREG2zDTyEH'
secret = 'KAd5OyuCkyW71YB6l8Q3g94jHgogWfXZ'
oauth = require "OAuth"
client = oauth.new(key, secret,
  { RequestToken='http://www.plurk.com/OAuth/request_token',
    AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
    AccessToken='http://www.plurk.com/OAuth/access_token'} )

local value = client:RequestToken()
local token_key = value.oauth_token
local token_secret = value.oauth_token_secret
local callbacl_confirm = value.oauth_callback_confirm
print("Token key: "..token_key.."\nToken secret: "..token_secret.." "..value.oauth_callback_confirmed)
local new_url = client:BuildAuthorizationUrl({ oauth_token = token_key, })
print("Redirect to URL:")
print(new_url)
local ffurl = 'd:/PortableApp/FirefoxPortable/FirefoxPortable.exe '..new_url
os.execute(ffurl) -- need to escape character
print("Enter pin")

local oauth_verifier = assert(io.read("*n"))
oauth_verifier = tostring(oauth_verifier)
print(oauth_verifier)

client = oauth.new(key, secret,
  { RequestToken='http://www.plurk.com/OAuth/request_token',
    AuthorizeUser = {"http://www.plurk.com/OAuth/authorize", method = "GET"},
    AccessToken='http://www.plurk.com/OAuth/access_token'
   }, {
    OAuthToken = token_key,
    OAuthVerifier = oauth_verifier
  })
client:SetTokenSecret(token_secret)

local values, err, headers, status, body = client:GetAccessToken()
local access_token = {}
for k, v in pairs(values) do
  print(k,v)
  access_token[k] = v
end

local response_code, response_headers, response_status_line, response_body =
    client:PerformRequest("POST", "http://www.plurk.com/APP/Users/getKarmaStats", {oauth_token = access_token['oauth_token']})
print("response_code", response_code)
print("response_status_line", response_status_line)
for k,v in pairs(response_headers) do print(k,v) end
print("response_body", response_body)
