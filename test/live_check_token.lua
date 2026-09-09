-- Opt-in only. Never run this file in normal CI.
local plurk = require("LuaPlurk")

local app_key = os.getenv("PLURK_TEST_APP_KEY")
local app_secret = os.getenv("PLURK_TEST_APP_SECRET")
local access_token = os.getenv("PLURK_TEST_ACCESS_TOKEN")
local access_token_secret = os.getenv("PLURK_TEST_ACCESS_TOKEN_SECRET")

assert(app_key and app_secret and access_token and access_token_secret,
    "set PLURK_TEST_APP_KEY, PLURK_TEST_APP_SECRET, PLURK_TEST_ACCESS_TOKEN, and PLURK_TEST_ACCESS_TOKEN_SECRET")

local client = assert(plurk.new({ app_key = app_key, app_secret = app_secret,
    access_token = access_token, access_token_secret = access_token_secret }))
local result, err = client:oauth_utils():check_token()
assert(result, err and err.message or "check_token failed")
print("Live check_token passed")

local server_time, time_err = client:oauth_utils():check_time()
assert(server_time, time_err and time_err.message or "check_time failed")
print("Live check_time passed")

local echoed, echo_err = client:oauth_utils():echo({ marker = "luaplurk-phase1" })
assert(echoed, echo_err and echo_err.message or "echo failed")
print("Live echo passed")
