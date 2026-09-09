local oauth1 = require("luaplurk.oauth1")
local transport_factory = require("luaplurk.transport")

local Client = {}
Client.__index = Client

local request_counter = 0

local function request_id()
    request_counter = request_counter + 1
    return string.format("lua-plurk-%d-%d", os.time(), request_counter)
end

local function failure(kind, message, id, extra)
    local result = { kind = kind, message = message, retryable = false, request_id = id }
    if extra then
        local key, value
        for key, value in pairs(extra) do result[key] = value end
    end
    return result
end

local function add_params(target, values)
    local key, value
    for key, value in pairs(values or {}) do
        if type(key) ~= "string" or (type(value) ~= "string" and type(value) ~= "number"
            and type(value) ~= "boolean") then
            return nil, "parameters must have string keys and scalar values"
        end
        table.insert(target, { key = key, value = tostring(value) })
    end
    return true
end

local function form_encode(values)
    local list = {}
    local ok, message = add_params(list, values)
    if not ok then return nil, message end
    table.sort(list, function(left, right)
        local left_key = oauth1.percent_encode(left.key)
        local right_key = oauth1.percent_encode(right.key)
        if left_key ~= right_key then return left_key < right_key end
        return oauth1.percent_encode(left.value) < oauth1.percent_encode(right.value)
    end)
    local parts, _, entry = {}, nil, nil
    for _, entry in ipairs(list) do
        table.insert(parts, oauth1.percent_encode(entry.key) .. "=" .. oauth1.percent_encode(entry.value))
    end
    return table.concat(parts, "&")
end

local function parse_query(body)
    local values = {}
    local pair
    for pair in string.gmatch(body or "", "[^&]+") do
        local key, value = pair:match("^([^=]+)=?(.*)$")
        if key then values[oauth1.percent_decode(key)] = oauth1.percent_decode(value) end
    end
    return values
end

function Client.new(options)
    if type(options) ~= "table" or type(options.app_key) ~= "string" or options.app_key == ""
        or type(options.app_secret) ~= "string" or options.app_secret == "" then
        return nil, failure("validation", "app_key and app_secret are required", request_id())
    end
    local timeout = options.timeout_seconds or 30
    if type(timeout) ~= "number" or timeout <= 0 or timeout >= math.huge or timeout ~= timeout then
        return nil, failure("validation", "timeout_seconds must be a finite positive number", request_id())
    end
    local transport = options.transport
    if transport == nil then
        transport = transport_factory.new({ ca_file = options.ca_file })
    end
    if type(transport) ~= "function" then
        return nil, failure("validation", "transport must be a function", request_id())
    end
    return setmetatable({ app_key = options.app_key, app_secret = options.app_secret,
        access_token = options.access_token, access_token_secret = options.access_token_secret,
        timeout_seconds = timeout, transport = transport }, Client), nil
end

function Client:_perform(method, url, api_params, token, token_secret, oauth_extra, decode_json)
    local id = request_id()
    local signed = {}
    local ok, message = add_params(signed, api_params)
    if not ok then return nil, failure("validation", message, id) end
    local oauth_params = {
        { key = "oauth_consumer_key", value = self.app_key },
        { key = "oauth_nonce", value = tostring(os.time()) .. tostring(math.random(100000, 999999)) },
        { key = "oauth_signature_method", value = "HMAC-SHA1" },
        { key = "oauth_timestamp", value = tostring(os.time()) },
        { key = "oauth_version", value = "1.0" },
    }
    if token then table.insert(oauth_params, { key = "oauth_token", value = token }) end
    local _, entry
    for _, entry in ipairs(oauth_extra or {}) do table.insert(oauth_params, entry) end
    for _, entry in ipairs(oauth_params) do table.insert(signed, entry) end
    local signature, signing_error = oauth1.sign(method, url, signed, self.app_secret, token_secret)
    if not signature then return nil, failure(signing_error.kind or "oauth", "OAuth signing failed", id) end
    table.insert(oauth_params, { key = "oauth_signature", value = signature })

    local request_url, body = url, nil
    local encoded, encoding_error = form_encode(api_params)
    if not encoded then return nil, failure("validation", encoding_error, id) end
    if method == "GET" and encoded ~= "" then request_url = url .. "?" .. encoded
    elseif method == "POST" then body = encoded end
    local response_body, status, response_headers, transport_error = self.transport(method,
        request_url, { Authorization = oauth1.authorization_header(oauth_params),
            Accept = decode_json and "application/json" or "*/*",
            ["Content-Type"] = method == "POST" and "application/x-www-form-urlencoded" or nil },
        body, self.timeout_seconds)
    if transport_error then
        transport_error.request_id = id
        return nil, transport_error
    end
    if not status or status < 200 or status >= 300 then
        local kind = (status == 401 or status == 403) and "oauth" or "http"
        local api_error
        local ok_json, json = pcall(require, "dkjson")
        if ok_json and response_body and response_body ~= "" then
            local decoded = json.decode(response_body)
            if type(decoded) == "table" then
                api_error = decoded.error_text or decoded.error or decoded.message
                if api_error and kind ~= "oauth" then kind = "api" end
            end
        end
        return nil, failure(kind, "HTTP request failed", id,
            { status = status, api_error = api_error,
                retryable = status == 429 or (status and status >= 500) or false })
    end
    if not decode_json then return response_body, nil, response_headers end
    if response_body == "" then return true, nil, response_headers end
    local ok_json, json = pcall(require, "dkjson")
    if not ok_json then return nil, failure("decode", "dkjson is unavailable", id) end
    local result, _, decode_error = json.decode(response_body)
    if result == nil then return nil, failure("decode", "response JSON could not be decoded", id) end
    return result, nil, response_headers
end

function Client:request(method, path, params)
    if method ~= "GET" and method ~= "POST" then
        return nil, failure("validation", "method must be GET or POST", request_id())
    end
    if type(path) ~= "string" or not path:match("^/APP/") then
        return nil, failure("validation", "path must begin with /APP/", request_id())
    end
    if not self.access_token or not self.access_token_secret then
        return nil, failure("oauth", "access token credentials are required", request_id())
    end
    return self:_perform(method, "https://www.plurk.com" .. path, params or {},
        self.access_token, self.access_token_secret, nil, true)
end

function Client:request_token(callback_url)
    local body, err = self:_perform("POST", "https://www.plurk.com/OAuth/request_token", {}, nil,
        nil, { { key = "oauth_callback", value = callback_url or "oob" } }, false)
    if not body then return nil, err end
    local token = parse_query(body)
    if not token.oauth_token or not token.oauth_token_secret then
        return nil, failure("oauth", "OAuth request token response was invalid", request_id())
    end
    return token, nil
end

function Client:authorization_url(token, options)
    if type(token) ~= "string" or token == "" then
        return nil, failure("validation", "request token is required", request_id())
    end
    options = options or {}
    local url = "https://www.plurk.com/OAuth/authorize?oauth_token=" .. oauth1.percent_encode(token)
    if options.deviceid then url = url .. "&deviceid=" .. oauth1.percent_encode(options.deviceid) end
    if options.model then url = url .. "&model=" .. oauth1.percent_encode(options.model) end
    return url, nil
end

function Client:access_token(token, token_secret, verifier)
    if type(token) ~= "string" or type(token_secret) ~= "string" or type(verifier) ~= "string" then
        return nil, failure("validation", "request token, secret, and verifier are required", request_id())
    end
    local body, err = self:_perform("POST", "https://www.plurk.com/OAuth/access_token", {}, token,
        token_secret, { { key = "oauth_verifier", value = verifier } }, false)
    if not body then return nil, err end
    local credentials = parse_query(body)
    if not credentials.oauth_token or not credentials.oauth_token_secret then
        return nil, failure("oauth", "OAuth access token response was invalid", request_id())
    end
    self.access_token, self.access_token_secret = credentials.oauth_token, credentials.oauth_token_secret
    return credentials, nil
end

function Client:oauth_utils()
    return {
        check_time = function() return self:request("GET", "/APP/checkTime", {}) end,
        echo = function(_, params) return self:request("POST", "/APP/echo", params or {}) end,
        check_token = function() return self:request("GET", "/APP/checkToken", {}) end,
    }
end

return Client
