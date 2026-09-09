local hmac_sha1 = require("luaplurk.hmac_sha1")

local key = string.rep(string.char(11), 20)
local signature, err = hmac_sha1.sign(key, "Hi There")

if signature == nil and err.kind == "crypto" then
    print("HMAC-SHA1 vector skipped: install luaossl and LuaSocket MIME support")
    return
end

assert(err == nil)
assert(signature == "thcxhlUFcmTii8C2+zeMjvFGvgA=", "RFC 2202 test case 1 failed")

local oauth_signature, oauth_err = hmac_sha1.sign(
    "consumer%20secret&token%20secret",
    "GET&https%3A%2F%2Fwww.plurk.com%2FAPP%2FcheckTime&")
assert(oauth_err == nil)
assert(type(oauth_signature) == "string" and #oauth_signature > 0)

local result, validation_err = hmac_sha1.sign("secret-key", 42)
assert(result == nil)
assert(validation_err.kind == "validation")
assert(validation_err.message:find("secret-key", 1, true) == nil)

print("HMAC-SHA1 test vectors passed")
