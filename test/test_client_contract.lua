local Client = require("luaplurk.client")

local calls = {}
local function responder(method, url, headers, body, timeout)
    table.insert(calls, { method = method, url = url, headers = headers, body = body, timeout = timeout })
    return '{"ok":true}', 200, {}, nil
end

local client, new_err = Client.new({ app_key = "consumer", app_secret = "secret",
    access_token = "token", access_token_secret = "token-secret", timeout_seconds = 7,
    transport = responder })
assert(client and new_err == nil)

local result, err = client:request("GET", "/APP/Test/read", { title = "Ladies + Gentlemen" })
assert(result.ok and err == nil)
local get_call = calls[#calls]
assert(get_call.url:match("^https://www%.plurk%.com/APP/Test/read%?"))
assert(get_call.url:find("title=Ladies%%20%%2B%%20Gentlemen", 1) ~= nil)
assert(get_call.headers.Authorization:match("^OAuth "))
assert(get_call.headers.Authorization:find("title", 1, true) == nil)
assert(get_call.body == nil and get_call.timeout == 7)

result, err = client:request("POST", "/APP/Test/write", { content = "hello" })
assert(result.ok and err == nil)
local post_call = calls[#calls]
assert(post_call.body == "content=hello")
assert(post_call.headers["Content-Type"] == "application/x-www-form-urlencoded")

result, err = client:oauth_utils():check_token()
assert(result.ok and err == nil)
assert(calls[#calls].url == "https://www.plurk.com/APP/checkToken")

result, err = client:oauth_utils():check_time()
assert(result.ok and err == nil)
assert(calls[#calls].method == "GET" and calls[#calls].url == "https://www.plurk.com/APP/checkTime")

result, err = client:oauth_utils():echo({ marker = "phase1" })
assert(result.ok and err == nil)
assert(calls[#calls].method == "POST" and calls[#calls].url == "https://www.plurk.com/APP/echo")
assert(calls[#calls].body == "marker=phase1")

result, err = client:request("DELETE", "/APP/Test/read", {})
assert(result == nil and err.kind == "validation")
result, err = client:request("GET", "/not-app", {})
assert(result == nil and err.kind == "validation")

local malformed = assert(Client.new({ app_key = "a", app_secret = "b", access_token = "c",
    access_token_secret = "d", transport = function() return "{", 200, {}, nil end }))
result, err = malformed:request("GET", "/APP/Test/read", {})
assert(result == nil and err.kind == "decode" and err.request_id)

local unauthorized = assert(Client.new({ app_key = "a", app_secret = "b", access_token = "c",
    access_token_secret = "d", transport = function() return "denied", 401, {}, nil end }))
result, err = unauthorized:request("GET", "/APP/Test/read", {})
assert(result == nil and err.kind == "oauth" and err.status == 401)

local api_failure = assert(Client.new({ app_key = "a", app_secret = "b", access_token = "c",
    access_token_secret = "d", transport = function()
        return '{"error_text":"rate limited"}', 429, {}, nil
    end }))
result, err = api_failure:request("GET", "/APP/Test/read", {})
assert(result == nil and err.kind == "api" and err.api_error == "rate limited" and err.retryable)

local offline = assert(Client.new({ app_key = "a", app_secret = "b", access_token = "c",
    access_token_secret = "d", transport = function()
        return nil, nil, nil, { kind = "transport", message = "timeout", retryable = true }
    end }))
result, err = offline:request("GET", "/APP/Test/read", {})
assert(result == nil and err.kind == "transport" and err.retryable and err.request_id)

print("Client contract tests passed")
