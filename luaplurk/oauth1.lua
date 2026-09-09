local M = {}

-- RFC 3986: ALPHA / DIGIT / "-" / "." / "_" / "~"
local function is_unreserved(character)
    local code = string.byte(character)
    return (code >= 65 and code <= 90)
        or (code >= 97 and code <= 122)
        or (code >= 48 and code <= 57)
        or code == 45 or code == 46 or code == 95 or code == 126
end

function M.percent_encode(value)
    value = tostring(value)
    local result = {}
    local index

    for index = 1, #value do
        local character = value:sub(index, index)
        if is_unreserved(character) then
            table.insert(result, character)
        else
            table.insert(result, string.format("%%%02X", string.byte(character)))
        end
    end
    return table.concat(result)
end

function M.percent_decode(value)
    return tostring(value):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

-- `params` is an array of { key = ..., value = ... }; duplicate keys survive.
function M.normalized_parameters(params)
    local filtered = {}
    local _, parameter

    for _, parameter in ipairs(params) do
        if parameter.key ~= "oauth_signature" then
            table.insert(filtered, { key = parameter.key, value = parameter.value })
        end
    end

    table.sort(filtered, function(left, right)
        local left_key = M.percent_encode(left.key)
        local right_key = M.percent_encode(right.key)
        if left_key ~= right_key then
            return left_key < right_key
        end
        return M.percent_encode(left.value) < M.percent_encode(right.value)
    end)

    local parts = {}
    for _, parameter in ipairs(filtered) do
        table.insert(parts, M.percent_encode(parameter.key)
            .. "=" .. M.percent_encode(parameter.value))
    end
    return table.concat(parts, "&")
end

function M.signature_base_string(method, base_url, params)
    return string.upper(method) .. "&" .. M.percent_encode(base_url) .. "&"
        .. M.percent_encode(M.normalized_parameters(params))
end

function M.signing_key(consumer_secret, token_secret)
    return M.percent_encode(consumer_secret or "") .. "&"
        .. M.percent_encode(token_secret or "")
end

function M.authorization_header(params)
    local oauth_params = {}
    local _, parameter

    for _, parameter in ipairs(params) do
        if parameter.key:match("^oauth_") then
            table.insert(oauth_params, { key = parameter.key, value = parameter.value })
        end
    end

    table.sort(oauth_params, function(left, right)
        local left_key = M.percent_encode(left.key)
        local right_key = M.percent_encode(right.key)
        if left_key ~= right_key then
            return left_key < right_key
        end
        return M.percent_encode(left.value) < M.percent_encode(right.value)
    end)

    local parts = {}
    for _, parameter in ipairs(oauth_params) do
        table.insert(parts, M.percent_encode(parameter.key) .. "=\""
            .. M.percent_encode(parameter.value) .. "\"")
    end
    return "OAuth " .. table.concat(parts, ", ")
end

function M.sign(method, base_url, params, consumer_secret, token_secret)
    local hmac_sha1 = require("luaplurk.hmac_sha1")
    return hmac_sha1.sign(M.signing_key(consumer_secret, token_secret),
        M.signature_base_string(method, base_url, params))
end

return M
