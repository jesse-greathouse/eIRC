local cjson = require "cjson"
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

    ngx.log(ngx.DEBUG, "🔍 Instance ID: ", instance_id)
    ngx.log(ngx.DEBUG, "🔍 Chat Token Received: ", token or "nil")

    if not token then
        ngx.log(ngx.ERR, "❌ Missing chat_token query param")
        return http.exit(400, "Missing Token")
    end

    local ok, err = token_store.get_binding(token)
    if not ok then
        ngx.log(ngx.ERR, "❌ Token validation failed: ", err)
        return http.exit(err == "Token validation failed" and 400 or 401, "Unauthorized Token: " .. err)
    end

    -- Call API to get user object
    local user, api_err = api.get_user_by_token(token)
    if not user then
        ngx.log(ngx.ERR, "❌ Failed API response for token: ", token, ", error: ", api_err)
        return http.exit(500, "Token User Mismatch: " .. token)
    end

    -- Log user object
    local user_json = cjson.encode(user)
    ngx.log(ngx.DEBUG, "🔍 API User Response: ", user_json)

    -- Debug channels specifically
    ngx.log(ngx.DEBUG, "🔍 User Nick: ", user.nick or "nil")
    ngx.log(ngx.DEBUG, "🔍 User Channels: ", user.channels and cjson.encode(user.channels) or "nil")

    -- Proceed to run the IRC client
    server.run(user.nick, user.realname, env.irc_host(), env.irc_port(), user.channels or "", instance_id)
end

return _M
