local env = require "jesse-greathouse.eIRC.env"
local http = require "jesse-greathouse.eIRC.http"
local api = require "jesse-greathouse.eIRC.api.client"
local server = require "jesse-greathouse.eIRC.websocket.server"
local token_store = require "jesse-greathouse.eIRC.stores.token_store"

local _M = {}

function _M.route()
    local instance_id = ngx.var.request_id
    local args = ngx.req.get_uri_args()
    local token = args.chat_token

    -- validations
    if not token then
        ngx.log(ngx.ERR, "❌ Missing chat_token query param")
        return http.exit(400, "Missing chat_token")
    end

    local ok, err = token_store.get_binding(token)
    if not ok then
        ngx.log(ngx.ERR, "❌ Token validation failed: ", err)
        return http.exit(err == "Token validation failed" and 400 or 401, err)
    end

    local user, err = api.get_user_by_token(token)
    if not user then
        ngx.log(ngx.ERR, "❌ Token User Mismatch: " .. token, err)
        return http.exit(500, "Token User Mismatch: " .. token)
    end

    -- connect to headless irc client
    server.run(user.nick, env.irc_host(), env.irc_port(), user.channels or "", instance_id)
end

return _M
