local Client = require("luaplurk.client")

local requests = {}
local client = assert(Client.new({ app_key = "consumer", app_secret = "secret",
    transport = function(method, url, headers, body, timeout)
        table.insert(requests, { method = method, url = url, headers = headers, body = body })
        if url:find("request_token", 1, true) then
            return "oauth_token=request&oauth_token_secret=request-secret&oauth_callback_confirmed=true", 200, {}, nil
        end
        return "oauth_token=access&oauth_token_secret=access-secret", 200, {}, nil
    end }))

local request_token = assert(client:request_token("oob"))
assert(request_token.oauth_token == "request" and request_token.oauth_token_secret == "request-secret")
assert(requests[1].url == "https://www.plurk.com/OAuth/request_token")
assert(requests[1].headers.Authorization:find("oauth_callback=\"oob\"", 1, true))

local url = assert(client:authorization_url("request", { deviceid = "phone", model = "Lua Test" }))
assert(url == "https://www.plurk.com/OAuth/authorize?oauth_token=request&deviceid=phone&model=Lua%20Test")

local credentials = assert(client:access_token("request", "request-secret", "verifier"))
assert(credentials.oauth_token == "access" and client.access_token == "access")
assert(requests[2].url == "https://www.plurk.com/OAuth/access_token")
assert(requests[2].headers.Authorization:find("oauth_verifier=\"verifier\"", 1, true))

print("OAuth token-flow fixture tests passed")
