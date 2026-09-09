local oauth1 = require("luaplurk.oauth1")

assert(oauth1.percent_encode("abcABC123-._~") == "abcABC123-._~")
assert(oauth1.percent_encode("Ladies + Gentlemen") == "Ladies%20%2B%20Gentlemen")
assert(oauth1.percent_decode("Ladies%20%2B%20Gentlemen") == "Ladies + Gentlemen")

local params = {
    { key = "file", value = "vacation.jpg" },
    { key = "size", value = "original" },
    { key = "oauth_consumer_key", value = "dpf43f3p2l4k3l03" },
    { key = "oauth_token", value = "nnch734d00sl2jdk" },
    { key = "oauth_nonce", value = "kllo9940pd9333jh" },
    { key = "oauth_timestamp", value = "1191242096" },
    { key = "oauth_signature_method", value = "HMAC-SHA1" },
    { key = "oauth_version", value = "1.0" },
}

local expected = "file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03"
    .. "&oauth_nonce=kllo9940pd9333jh&oauth_signature_method=HMAC-SHA1"
    .. "&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk"
    .. "&oauth_version=1.0&size=original"
assert(oauth1.normalized_parameters(params) == expected)

local expected_base = "GET&http%3A%2F%2Fphotos.example.net%2Fphotos&"
    .. "file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03"
    .. "%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1"
    .. "%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk"
    .. "%26oauth_version%3D1.0%26size%3Doriginal"
assert(oauth1.signature_base_string("GET", "http://photos.example.net/photos", params)
    == expected_base)
assert(oauth1.signing_key("secret", "token_secret") == "secret&token_secret")

local header = oauth1.authorization_header({
    { key = "file", value = "vacation.jpg" },
    { key = "oauth_consumer_key", value = "dpf43f3p2l4k3l03" },
    { key = "oauth_token", value = "nnch734d00sl2jdk" },
})
assert(header:find("file", 1, true) == nil)
assert(header:find("oauth_consumer_key", 1, true) ~= nil)
assert(header:find("oauth_token", 1, true) ~= nil)
assert(oauth1.normalized_parameters({
    { key = "b", value = "2" }, { key = "a", value = "1" },
    { key = "b", value = "1" },
}) == "a=1&b=1&b=2")

print("OAuth 1.0a normalization tests passed")
