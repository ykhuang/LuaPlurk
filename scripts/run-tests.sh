#!/bin/sh
# Run the OAuth-free Phase 0 smoke test without modifying the checkout.
set -eu

LUA_BIN=${LUA_BIN:-}

if [ "$LUA_BIN" = "" ]; then
    for candidate in lua5.4 lua5.1 lua; do
        if command -v "$candidate" >/dev/null 2>&1; then
            LUA_BIN=$candidate
            break
        fi
    done
fi

if [ "$LUA_BIN" = "" ] || ! command -v "$LUA_BIN" >/dev/null 2>&1; then
    echo "error: Lua interpreter '$LUA_BIN' is unavailable" >&2
    exit 1
fi

STUB_DIR=$(mktemp -d "${TMPDIR:-/tmp}/luaplurk-oauth.XXXXXX")
cleanup() { rm -rf "$STUB_DIR"; }
trap cleanup EXIT HUP INT TERM

cat > "$STUB_DIR/OAuth.lua" <<'EOF'
local oauth = {}
function oauth.new()
   return {}
end
return oauth
EOF

echo "Using Lua interpreter: $LUA_BIN"
for test_file in test/test_*.lua; do
    LUA_PATH="$STUB_DIR/?.lua;./?.lua;;" "$LUA_BIN" "$test_file"
done
