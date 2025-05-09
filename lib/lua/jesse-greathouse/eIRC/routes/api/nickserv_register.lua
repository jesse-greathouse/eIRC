local cjson       = require "cjson"
local env         = require "jesse-greathouse.eIRC.env"
local http        = require "jesse-greathouse.eIRC.http"
local api         = require "jesse-greathouse.eIRC.api.client"
local irc         = require "jesse-greathouse.eIRC.websocket.server.irc_socket"
local token_store = require "jesse-greathouse.eIRC.stores.token_store"

local _M = {}

function _M.route()
	-- Read and parse JSON body
	ngx.req.read_body()
	local body = ngx.req.get_body_data()
	if not body then
		return http.exit(400, "Missing request body")
	end
	local ok, data = pcall(cjson.decode, body)
	if not ok or type(data) ~= "table" then
		return http.exit(400, "Invalid JSON payload")
	end

	-- Validate chat_token
	local token = data.chat_token
	if not token then
		return http.exit(400, "Missing chat_token")
	end
	local bound, bind_err = token_store.get_binding(token)
	if not bound then
		local code = (bind_err == "Token validation failed") and 400 or 401
		return http.exit(code, "Unauthorized Token: " .. bind_err)
	end

	-- Fetch user from Laravel
	local user, api_err = api.get_user_by_token(token)
	if not user then
		return http.exit(500, "User lookup failed: " .. (api_err or "unknown"))
	end

	-- Spawn a one-off IRC client instance
	local instance = ngx.var.request_id .. "-reg"
	local spawned, spawn_err = irc.start_client(
		user.nick,
		user.realname,
		env.irc_host(),
		env.irc_port(),
		{},              -- no channels
		instance,
		user.sasl_secret
	)
	if not spawned then
		return http.exit(500, "IRC client spawn failed: " .. (spawn_err or "unknown"))
	end

	-- Connect to the IRC socket
	local sock = irc.connect_with_retry(5, 0.1, instance)
	if not sock then
		return http.exit(500, "IRC socket connect failed")
	end

	-- Wait for MOTD end (numeric 376 or 422)
	do
		local deadline = ngx.now() + 10
		while ngx.now() < deadline do
		local line, err = sock:receive("*l")
		if not line then
			return http.exit(500, "Error reading MOTD: " .. (err or "nil"))
		end
		if line:find(" 376 ") or line:find(" 422 ") then
			break
		end
		end
		if ngx.now() >= deadline then
		return http.exit(504, "Timeout waiting for IRC MOTD end")
		end
	end

	-- Send the REGISTER via /input
    local register_cmd = "/input PRIVMSG NickServ :REGISTER "
                        .. user.sasl_secret .. " " .. user.email .. "\n"
    local ok, send_err = sock:send(register_cmd)
    if not ok then
        irc.close(instance)
        return http.exit(500, "Failed to send REGISTER: " .. (send_err or "unknown"))
    end

    -- Collect NickServ’s responses (up to 5s)
    local responses = {}
    local deadline  = ngx.now() + 5
    local success   = false
    local errorMsg

	deadline = ngx.now() + 5
    while ngx.now() < deadline do
        local line, err = sock:receive("*l")
        if not line then
            break
        end

        table.insert(responses, line)

        -- Only inspect NickServ NOTICE lines
        if line:match("^:NickServ") then
            local lower = line:lower()

            -- 1) Catch known error patterns first
            if lower:find("too long")
            or lower:find("usage")
            or lower:find("error")
            then
                errorMsg = line:match(":%s*(.+)$")
                success  = false
                break
            end

            -- 2) If it contains “registered”, mark success
            if lower:find("registered") then
                success = true
                break
            end
        end
    end

    irc.close(instance)

    return http.ok({
        success   = success,
        error     = success and nil or (errorMsg or "Unknown response"),
        responses = responses,
    })
end

return _M
