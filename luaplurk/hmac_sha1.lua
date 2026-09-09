local M = {}

local function crypto_error(message)
    return {
        kind = "crypto",
        message = message,
        retryable = false,
    }
end

function M.sign(key, message)
    if type(key) ~= "string" or type(message) ~= "string" then
        return nil, {
            kind = "validation",
            message = "key and message must be strings",
            retryable = false,
        }
    end

    local ok_hmac, hmac = pcall(require, "openssl.hmac")
    if not ok_hmac then
        return nil, crypto_error("luaossl HMAC support is unavailable")
    end

    local ok_mime, mime = pcall(require, "mime")
    if not ok_mime then
        return nil, crypto_error("LuaSocket MIME support is unavailable")
    end

    local ok_context, context = pcall(hmac.new, key, "sha1")
    if not ok_context then
        return nil, crypto_error("unable to initialize HMAC-SHA1")
    end

    local ok_signature, raw_signature = pcall(context.final, context, message)
    if not ok_signature then
        return nil, crypto_error("unable to calculate HMAC-SHA1")
    end

    local ok_base64, signature = pcall(mime.b64, raw_signature)
    if not ok_base64 then
        return nil, crypto_error("unable to Base64 encode HMAC-SHA1")
    end

    return (signature:gsub("%s+$", "")), nil
end

return M
