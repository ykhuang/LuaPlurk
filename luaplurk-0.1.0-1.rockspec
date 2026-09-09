package = "luaplurk"
version = "0.1.0-1"

source = {
   url = "https://github.com/ykhuang/LuaPlurk",
}

description = {
   summary = "Lua client library for the Plurk API",
   detailed = "LuaPlurk is being modernized into a secure, tested Plurk API SDK.",
   license = "MIT",
}

dependencies = {
   "lua >= 5.1",
   "luasec",
   "luasocket",
   "luaossl",
   "dkjson",
}

build = {
   type = "builtin",
   modules = {
      LuaPlurk = "LuaPlurk.lua",
      ["luaplurk.hmac_sha1"] = "luaplurk/hmac_sha1.lua",
      ["luaplurk.oauth1"] = "luaplurk/oauth1.lua",
      ["luaplurk.transport"] = "luaplurk/transport.lua",
      ["luaplurk.client"] = "luaplurk/client.lua",
   },
}
