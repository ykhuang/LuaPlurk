local M = {}

local function err(kind, message, retryable)
    return { kind = kind, message = message, retryable = retryable }
end

local function valid_timeout(timeout)
    return type(timeout) == "number" and timeout > 0
        and timeout < math.huge and timeout == timeout
end

local function find_ca_file(configured)
    local candidates = { "/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/cert.pem",
        "/etc/pki/tls/certs/ca-bundle.crt" }
    if configured then table.insert(candidates, 1, configured) end
    local _, path
    for _, path in ipairs(candidates) do
        if path then
            local handle = io.open(path, "rb")
            if handle then
                handle:close()
                return path
            end
        end
    end
    return nil
end

local function production_requester(ca_file)
    return function(method, url, headers, body, timeout)
        local ok_https, https = pcall(require, "ssl.https")
        local ok_ltn12, ltn12 = pcall(require, "ltn12")
        if not ok_https or not ok_ltn12 then
            return nil, nil, nil, "HTTPS dependencies are unavailable"
        end

        local trust_store = find_ca_file(ca_file)
        if not trust_store then
            return nil, nil, nil, "a CA trust store is unavailable"
        end

        local chunks = {}
        local old_timeout = https.TIMEOUT
        local result_body, status, response_headers
        local ok, failure = xpcall(function()
            https.TIMEOUT = timeout
            local request_headers = {}
            local key, value
            for key, value in pairs(headers) do
                request_headers[key] = value
            end
            if body then
                request_headers["content-length"] = tostring(#body)
            end
            local success, code, returned_headers = https.request({
                url = url,
                method = method,
                headers = request_headers,
                source = body and ltn12.source.string(body) or nil,
                sink = ltn12.sink.table(chunks),
                protocol = "any",
                options = { "all", "no_sslv2", "no_sslv3", "no_tlsv1" },
                verify = "peer",
                cafile = trust_store,
                redirect = false,
            })
            if not success then
                local reason = tostring(code or "")
                if reason:lower():find("certificate", 1, true) then
                    error("TLS certificate verification failed")
                elseif reason:lower():find("timeout", 1, true) then
                    error("HTTPS connection timed out")
                else
                    error("HTTPS connection failed")
                end
            end
            result_body = table.concat(chunks)
            status = tonumber(code)
            response_headers = returned_headers or {}
        end, function()
            return "HTTPS request failed"
        end)
        https.TIMEOUT = old_timeout

        if not ok then
            return nil, nil, nil, failure
        end
        return result_body, status, response_headers, nil
    end
end

function M.new(options)
    options = options or {}
    local requester = options.requester or production_requester(options.ca_file)

    return function(method, url, headers, body, timeout)
        if method ~= "GET" and method ~= "POST" then
            return nil, nil, nil, err("validation", "method must be GET or POST", false)
        end
        if type(url) ~= "string" or not url:match("^https://") then
            return nil, nil, nil, err("validation", "URL must use HTTPS", false)
        end
        if type(headers) ~= "table" or (body ~= nil and type(body) ~= "string")
            or not valid_timeout(timeout) then
            return nil, nil, nil, err("validation", "invalid transport arguments", false)
        end

        local ok, response_body, status, response_headers, failure = pcall(
            requester, method, url, headers, body, timeout)
        if not ok or response_body == nil then
            local message = type(failure) == "string" and failure or "HTTPS request failed"
            return nil, nil, nil, err("transport", message, true)
        end
        if failure then
            return nil, nil, nil, err("transport", "HTTPS request failed", true)
        end
        return response_body, status, response_headers, nil
    end
end

return M
