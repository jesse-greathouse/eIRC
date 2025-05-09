local cjson       = require "cjson"
local env         = require "jesse-greathouse.eIRC.env"
local http        = require "jesse-greathouse.eIRC.http"
local api         = require "jesse-greathouse.eIRC.api.client"
local irc         = require "jesse-greathouse.eIRC.websocket.server.irc_socket"
local token_store = require "jesse-greathouse.eIRC.stores.token_store"

local _M = {}

function _M.route()
    -- Parse and validate JSON body
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        return http.exit(400, "Missing request body")
    end
    local ok, data = pcall(cjson.decode, body)
    if not ok or type(data) ~= "table" then
        return http.exit(400, "Invalid JSON payload")
    end

    local token      = data.chat_token
    local new_secret = data.new_sasl_secret
    if not token or not new_secret then
        return http.exit(400, "Missing chat_token or new_sasl_secret")
    end

    -- Validate chat_token
    local bound, bind_err = token_store.get_binding(token)
    if not bound then
        local code = (bind_err == "Token validation failed") and 400 or 401
        return http.exit(code, "Unauthorized Token: " .. bind_err)
    end

    -- Fetch authenticated user from Laravel
    local user, api_err = api.get_user_by_token(token)
    if not user then
        return http.exit(500, "User lookup failed: " .. (api_err or "unknown"))
    end

    -- Spawn a headless IRC client instance
    local instance = ngx.var.request_id .. "-pw"
    local spawned, spawn_err = irc.start_client(
        user.nick,
        user.realname,
        env.irc_host(),
        env.irc_port(),
        {},                -- no channels
        instance,
        user.sasl_secret   -- current SASL secret
    )
    if not spawned then
        return http.exit(500, "IRC client spawn failed: " .. (spawn_err or "unknown"))
    end

    -- Connect to the IRC socket (retry up to 5s)
    local sock = irc.connect_with_retry(5, 0.1, instance)
    if not sock then
        return http.exit(500, "IRC socket connect failed")
    end

    -- Wait for end-of-MOTD (numeric 376 or 422)
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
    end

	-- Authenticate with NickServ IDENTIFY
	sock:send("/input PRIVMSG NickServ :IDENTIFY " .. user.sasl_secret .. "\n")

	local auth_ok = false
	local auth_deadline = ngx.now() + 5
	while ngx.now() < auth_deadline do
		local line = sock:receive("*l")
		if not line then break end

		-- lowercase the incoming line
		local lower = line:lower()

		-- only check for positive success patterns
        -- different service providers can have different responses
		if line:match("%s900%s")       -- numeric 900 “You are now logged in as …”
        or lower:find("you are now")   -- covers “you are now recognized” / “you are now identified”
        or lower:find("accepted")      -- covers “Password accepted”
        or lower:find("logged in")     -- covers “You are now logged in”
        then
            auth_ok = true
            break
        end

		-- otherwise, ignore and keep waiting until timeout
	end

	-- if we never saw a success, abort with UNAUTHORIZED
	if not auth_ok then
		irc.close(instance)
		return http.exit(401, cjson.encode({
			success = false,
			error   = "NickServ IDENTIFY failed or timed out",
		}))
	end

	-- At this point auth_ok == true, so continue to password-change attempts
    -- Attempt each password‐change syntax in order
    -- Different service providers implement this in different ways
    local templates = {
        "PRIVMSG NickServ :SET PASSWORD %s",
        "PRIVMSG NickServ :SET PASSWD %s %s",
        "PRIVMSG NickServ :CHPASS %s",
        "PRIVMSG NickServ :PASSWD %s %s",
        "PRIVMSG NickServ :SIDENTIFY %s",
    }
    local responses = {}
    local success   = false

    for _, tmpl in ipairs(templates) do
        local cmd
        if tmpl:find("%%s %s") then
            -- those two‐arg forms need old + new
            cmd = tmpl:format(user.sasl_secret, new_secret)
        else
            cmd = tmpl:format(new_secret)
        end

        -- prefix with "/input " so C++ handler emits raw
        sock:send("/input " .. cmd .. "\n")

        -- collect up to 5s of replies for this attempt
        local deadline = ngx.now() + 5
        while ngx.now() < deadline do
            local line = sock:receive("*l")
            if not line then break end
            table.insert(responses, line)
            if line:match("^:NickServ") then
                local lower = line:lower()
                -- simplistic success detection
                if lower:find("password") or lower:find("success") then
                    success = true
                    break
                -- bail early on obvious errors
                elseif lower:find("unknown") or lower:find("error") then
                    break
                end
            end
        end

        if success then
            break
        end
    end

    -- Tear down the IRC client
    irc.close(instance)

    -- Return JSON success/failure
    if success then
        return http.ok({ success = true, responses = responses })
    else
        return http.exit(500, cjson.encode({
            success   = false,
            responses = responses,
        }))
    end
end

return _M
