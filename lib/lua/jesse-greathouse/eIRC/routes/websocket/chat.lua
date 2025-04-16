local api = require "jesse-greathouse.eIRC.api.client"
local server = require "jesse-greathouse.eIRC.websocket.server"
local token_store = require "jesse-greathouse.eIRC.stores.token_store"

local _M = {}

function _M.route()
    local instance_id = ngx.var.request_id
    local args = ngx.req.get_uri_args()
    local token = args.chat_token

    local ok, err = token_store.get_binding(token, instance_id)
    if not ok then
        ngx.log(ngx.ERR, "❌ Token validation failed: ", err)
        ngx.status = err == "Missing token" and 400 or 401
        return ngx.exit(ngx.status)
    end

    local user, err = api.get_user_by_token(token)
    if not user then
        ngx.log(ngx.ERR, "❌ Failed to fetch user: ", err)
        ngx.status = 500
        return ngx.exit(500)
    end

    local irc_host = os.getenv("IRC_SERVER_HOST") or "127.0.0.1"
    local irc_port = tonumber(os.getenv("IRC_SERVER_PORT")) or 6667

    server.run(
        user.nick,
        irc_host,
        irc_port,
        user.channels or "",
        instance_id
    )
end

return _M
