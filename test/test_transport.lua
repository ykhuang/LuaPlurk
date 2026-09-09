local transport = require("luaplurk.transport")

local called = false
local requester = function(method, url, headers, body, timeout)
    called = true
    assert(method == "GET" and url == "https://example.test/resource")
    assert(type(headers) == "table" and body == nil and timeout == 3)
    return "{}", 200, { content_type = "application/json" }, nil
end
local request = transport.new({ requester = requester })
local body, status, headers, err = request("GET", "https://example.test/resource", {}, nil, 3)
assert(called and body == "{}" and status == 200 and headers.content_type and err == nil)

body, status, headers, err = request("GET", "http://example.test/resource", {}, nil, 3)
assert(body == nil and status == nil and headers == nil and err.kind == "validation")
body, status, headers, err = request("POST", "https://example.test/resource", {}, 3, 3)
assert(body == nil and err.kind == "validation")
body, status, headers, err = request("GET", "https://example.test/resource", {}, nil, 0)
assert(body == nil and err.kind == "validation")

local timeout_request = transport.new({ requester = function()
    error("timeout")
end })
body, status, headers, err = timeout_request("GET", "https://example.test/resource", {}, nil, 3)
assert(body == nil and status == nil and headers == nil and err.kind == "transport" and err.retryable)

print("HTTPS transport fixture tests passed")
