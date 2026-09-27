local Client = require("luaplurk.client")

local calls = {}
local client = assert(Client.new({
    app_key = "consumer",
    app_secret = "secret",
    access_token = "token",
    access_token_secret = "token-secret",
    transport = function(method, url, headers, body)
        table.insert(calls, { method = method, url = url, headers = headers, body = body })
        return '{"ok":true}', 200, {}, nil
    end,
}))

local function expect(path, invoke, query)
    local result, err = invoke()
    assert(result and result.ok and err == nil)
    local call = calls[#calls]
    assert(call.method == "GET")
    assert(call.body == nil)
    assert(call.url:match("^https://www%.plurk%.com" .. path))
    assert(call.headers.Authorization:match("^OAuth "))
    if query then assert(call.url:find(query, 1, true) ~= nil) end
end

expect("/APP/Users/me", function() return client:users():me() end)
expect("/APP/Users/getKarmaStats", function() return client:users():karma_stats() end)
expect("/APP/Profile/getOwnProfile", function() return client:profile():own() end)
expect("/APP/Profile/getPublicProfile", function() return client:profile():public("plurkapi") end,
    "user_id=plurkapi")
expect("/APP/Polling/getPlurks", function() return client:polling():plurks("2026-01-01T00:00:00", { limit = 20 }) end,
    "limit=20&offset=2026-01-01T00%3A00%3A00")
expect("/APP/Polling/getUnreadCount", function() return client:polling():unread_count() end)
expect("/APP/Timeline/getPlurk", function() return client:timeline():get(42, { minimal_data = true }) end,
    "minimal_data=true&plurk_id=42")
expect("/APP/Timeline/getPlurks", function() return client:timeline():list({ limit = 10 }) end, "limit=10")
expect("/APP/Timeline/getUnreadPlurks", function() return client:timeline():unread({ filter = "my" }) end,
    "filter=my")
expect("/APP/Timeline/getPublicPlurks", function() return client:timeline():public(42, { limit = 10 }) end,
    "limit=10&user_id=42")
expect("/APP/Responses/get", function() return client:responses():list(42, { count = 5 }) end,
    "count=5&plurk_id=42")
expect("/APP/FriendsFans/getFriendsByOffset", function() return client:friends_fans():friends(42, { offset = 10 }) end,
    "offset=10&user_id=42")
expect("/APP/FriendsFans/getFansByOffset", function() return client:friends_fans():fans(42, { limit = 10 }) end,
    "limit=10&user_id=42")
expect("/APP/FriendsFans/getFollowingByOffset", function() return client:friends_fans():following({ offset = 10 }) end,
    "offset=10")
expect("/APP/FriendsFans/getCompletion", function() return client:friends_fans():completion() end)
expect("/APP/Alerts/getActive", function() return client:alerts():active() end)
expect("/APP/Alerts/getHistory", function() return client:alerts():history() end)
expect("/APP/PlurkSearch/search", function() return client:search():plurks("lua sdk", { offset = 10 }) end,
    "offset=10&query=lua%20sdk")
expect("/APP/UserSearch/search", function() return client:search():users("lua", { offset = 10 }) end,
    "offset=10&query=lua")
expect("/APP/Emoticons/get", function() return client:emoticons():get() end)
expect("/APP/Blocks/get", function() return client:blocks():list({ offset = 10 }) end, "offset=10")
expect("/APP/Cliques/getCliques", function() return client:cliques():list() end)
expect("/APP/Cliques/getClique", function() return client:cliques():get("Close Friends") end,
    "clique_name=Close%20Friends")

local before = #calls
local result, err = client:profile():public(nil)
assert(result == nil and err.kind == "validation")
assert(#calls == before)
result, err = client:polling():plurks("", {})
assert(result == nil and err.kind == "validation")
assert(#calls == before)
result, err = client:timeline():list("not a table")
assert(result == nil and err.kind == "validation")
assert(#calls == before)
result, err = client:search():users("lua", { nested = {} })
assert(result == nil and err.kind == "validation")
assert(#calls == before)

print("Read endpoint fixture tests passed")
