local _M = {}
local ws_server = require "resty.websocket.server"
local irc = require "jesse-greathouse.eIRC.websocket.server.irc_socket"
local http = require "jesse-greathouse.eIRC.http"

--[[
    server.run(...)
    This function initializes a WebSocket connection and connects it to a per-user IRC client.
    It is the client-side bridge for the IRC i/o.

    Parameters:
        - instance_id: Unique ID for this WebSocket + IRC client session

    Logical Flow:
        Validate required inputs
        Initialize WebSocket connection
        Spawn headless IRC client
        Retry-connect to IRC UNIX socket
        Start IRC receive thread → pipe into WebSocket
        Enter WebSocket receive loop → pipe into IRC
        On disconnect: shutdown IRC and WebSocket
--]]
function _M.run(nick, realname, server_addr, port, channels, instance_id)
    -- Validate instance ID
    if not instance_id or type(instance_id) ~= "string" or instance_id == "" then
        return http.exit(400, "Missing or invalid instance_id")
    end

    -- Create WebSocket server object
    local wb, err = ws_server:new{
        timeout = 5000,
        max_payload_len = 65535
    }

    if not wb then
        ngx.log(ngx.ERR, "WebSocket init failed: ", err)
        return http.exit(444, "WebSocket failed to initialize")
    end

    -- Spawn IRC client process if it isn’t running yet
    local ok, err = irc.start_client(nick, realname, server_addr, port, channels, instance_id)
    if not ok then
        wb:send_text("IRC client startup failed: " .. (err or "unknown error"))
        return http.exit(444, "IRC client startup failed")
    end

    -- Attempt to connect to the IRC client’s UNIX socket with retry logic
    if not irc.connect_with_retry(10, 0.1, instance_id) then
        local msg = "IRC socket connection failed after 10 attempts"
        wb:send_text(msg)
        return http.exit(444, msg)
    end

    -- Begin a coroutine to read lines from IRC and stream them to WebSocket
    irc.receive(instance_id, wb)

    -- Main WebSocket receive loop
    while true do
        local data, typ, err = wb:recv_frame()

        if wb.fatal then
            ngx.log(ngx.ERR, "WebSocket fatal error: ", err)
            break
        end

        -- WebSocket was idle — send a ping to keep connection alive
        if not data then
            local ok, err = wb:send_ping()
            if not ok then
                ngx.log(ngx.ERR, "Ping failed: ", err)
                break
            end

        -- Text message from frontend → send to IRC client
        elseif typ == "text" then
            local ok, err = irc.send(instance_id, data)
            if not ok then
                wb:send_text("IRC send error: " .. (err or "unknown"))
            end

        -- Ping → reply with pong
        elseif typ == "ping" then
            wb:send_pong()

        -- Pong → optional, but logged
        elseif typ == "pong" then
            ngx.log(ngx.INFO, "Received pong")

        -- Client closed the WebSocket
        elseif typ == "close" then
            break
        end
    end

    -- Cleanup on disconnect or fatal error

    -- Gracefully tell IRC client to quit
    irc.send(instance_id, "/quit")

    -- Close IRC socket and kill state
    irc.close(instance_id)

    -- Terminate WebSocket connection
    wb:send_close()
end

return _M
