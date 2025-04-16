local api = require "jesse-greathouse.eIRC.api.client"
local server = require "jesse-greathouse.eIRC.websocket.server"

local _M = {}

function _M.route()
    local instance_id = ngx.var.request_id
    local args = ngx.req.get_uri_args()
    local token = args.chat_token

    if not token then
        ngx.log(ngx.ERR, "❌ Missing chat_token arg")
        ngx.status = 400
        return ngx.exit(400)
    end

    local dict = ngx.shared.token_binding
    local existing = dict:get(token)

    if existing and existing ~= instance_id then
        ngx.log(ngx.ERR, "❌ Token reuse: bound to instance ", existing)
        ngx.status = 401
        return ngx.exit(401)
    end

    dict:set(token, instance_id, 180)

    local user, err = api.get_user_by_token(token)
    if not user then
        ngx.log(ngx.ERR, "❌ Failed to fetch user: ", err)
        ngx.status = 500
        return ngx.exit(500)
    end

    server.run(
        user.nick,
        "127.0.0.1",
        6667,
        user.channels or "",
        instance_id
    )
end

return _M
