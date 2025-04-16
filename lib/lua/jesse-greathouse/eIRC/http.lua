local cjson = require "cjson"

local _M = {}

-- Generic exit with JSON error payload
function _M.exit(status, message)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode({ error = message or "Unknown error" }))
    return ngx.exit(status)
end

-- Sends a 200 OK with a JSON payload
function _M.ok(payload)
    ngx.status = 200
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode(payload or { success = true }))
    return ngx.exit(200)
end

-- Sends a response with a custom status and JSON payload
function _M.json(status, payload)
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode(payload or {}))
    return ngx.exit(status)
end

return _M
