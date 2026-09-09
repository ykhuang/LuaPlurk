-- Phase 0 smoke test: load only; never perform OAuth or HTTP work.
local plurk = require("LuaPlurk")

assert(type(plurk) == "table", "LuaPlurk must export a table")

for _, name in ipairs({
   "init", "init_client", "getAuthorizedUrl", "getAccessToken", "plurkRequest",
}) do
   assert(type(plurk[name]) == "function", "LuaPlurk." .. name .. " must be a function")
end

print("Phase 0 smoke test passed")
