--[[
    LuaPlurk: a Lua implementation of Plurk OAuth
    Legacy module-level functions are deprecated; prefer LuaPlurk.new().
]]--

local Client = require("luaplurk.client")
local LuaPlurk = {}
local default_client

function LuaPlurk.new(options)
    return Client.new(options)
end

function LuaPlurk.init(key, secret)
    local client, err = Client.new({ app_key = key, app_secret = secret })
    if not client then return nil, err end
    default_client = client
    local token, token_err = client:request_token("oob")
    if not token then return nil, token_err end
    return token.oauth_callback_confirmed, token.oauth_token, token.oauth_token_secret
end

function LuaPlurk.init_client(key, secret, token_key, token_secret)
    local client, err = Client.new({ app_key = key, app_secret = secret,
        access_token = token_key, access_token_secret = token_secret })
    if not client then return nil, err end
    default_client = client
    return true, nil
end

function LuaPlurk.getAuthorizedUrl(token)
    if not default_client then return nil, { kind = "validation", message = "client is not initialized", retryable = false } end
    return default_client:authorization_url(token)
end

function LuaPlurk.getAccessToken(token, secret, verifier)
    if not default_client then return nil, { kind = "validation", message = "client is not initialized", retryable = false } end
    local values, err = default_client:access_token(token, secret, verifier)
    if not values then return nil, err end
    return values.oauth_token, values.oauth_token_secret
end

function LuaPlurk.plurkRequest(api, args)
    if not default_client then return nil, { kind = "validation", message = "client is not initialized", retryable = false } end
    return default_client:request("POST", api, args or {})
end

return LuaPlurk
