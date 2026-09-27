-- Opt-in only. Never run this file in normal CI.
-- This suite performs only read requests and intentionally does not print API data.
local plurk = require("LuaPlurk")

local function required_env(name)
    return assert(os.getenv(name), "set " .. name)
end

local client = assert(plurk.new({
    app_key = required_env("PLURK_TEST_APP_KEY"),
    app_secret = required_env("PLURK_TEST_APP_SECRET"),
    access_token = required_env("PLURK_TEST_ACCESS_TOKEN"),
    access_token_secret = required_env("PLURK_TEST_ACCESS_TOKEN_SECRET"),
}))

local function check(name, result, err)
    assert(result, err and err.message or name .. " failed")
    print("Live " .. name .. " passed")
    return result
end

local me = check("users.me", client:users():me())
assert(me.id, "users.me response did not include id")
check("users.karma_stats", client:users():karma_stats())
check("profile.own", client:profile():own())
check("profile.public", client:profile():public(me.id))
check("polling.plurks", client:polling():plurks(os.date("!%Y-%m-%dT%H:%M:%S"), { limit = 1 }))
check("polling.unread_count", client:polling():unread_count())

local timeline = check("timeline.list", client:timeline():list({ limit = 1 }))
check("timeline.unread", client:timeline():unread({ limit = 1 }))
check("timeline.public", client:timeline():public(me.id, { limit = 1 }))
if timeline.plurks and timeline.plurks[1] and timeline.plurks[1].plurk_id then
    local plurk_id = timeline.plurks[1].plurk_id
    check("timeline.get", client:timeline():get(plurk_id))
    check("responses.list", client:responses():list(plurk_id, { count = 1, minimal_data = true }))
else
    print("Live timeline.get and responses.list skipped: no accessible timeline plurk")
end

check("friends_fans.friends", client:friends_fans():friends(me.id, { limit = 1 }))
check("friends_fans.fans", client:friends_fans():fans(me.id, { limit = 1 }))
check("friends_fans.following", client:friends_fans():following({ limit = 1 }))
check("friends_fans.completion", client:friends_fans():completion())
check("alerts.active", client:alerts():active())
check("alerts.history", client:alerts():history())
check("search.plurks", client:search():plurks("LuaPlurkSDKValidation", { offset = 0 }))
check("search.users", client:search():users("plurk", { offset = 0 }))
check("emoticons.get", client:emoticons():get())
check("blocks.list", client:blocks():list({ offset = 0 }))

local cliques = check("cliques.list", client:cliques():list())
if cliques[1] then
    check("cliques.get", client:cliques():get(cliques[1]))
else
    print("Live cliques.get skipped: account has no cliques")
end
