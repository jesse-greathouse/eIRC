local _M = {}
local server = require "resty.websocket.server"
local irc = require "jesse-greathouse.eIRC.websocket.server.irc_socket"

function _M.run(nick, server_addr, port, channels, instance_id)
  if not nick or type(nick) ~= "string" or nick == "" or
     not server_addr or type(server_addr) ~= "string" or server_addr == "" or
     not port or type(port) ~= "number" or
     not channels or type(channels) ~= "string" or channels == "" or
     not instance_id or type(instance_id) ~= "string" or instance_id == "" then
    ngx.status = 400
    ngx.say("Bad request: missing or invalid parameters")
    return ngx.exit(400)
  end

  local wb, err = server:new{
    timeout = 5000,
    max_payload_len = 65535
  }

  if not wb then
    ngx.log(ngx.ERR, "Failed to new websocket: ", err)
    return ngx.exit(444)
  end

  local ok, err = irc.start_client(nick, server_addr, port, channels, instance_id)
  if not ok then
    wb:send_text("IRC client startup failed: " .. (err or "unknown error"))
    return ngx.exit(444)
  end

  if not irc.connect_with_retry(10, 0.1, instance_id) then
    wb:send_text("IRC socket connection failed after 10 attempts")
    return ngx.exit(444)
  end

  irc.receive(instance_id, wb)

  while true do
    local data, typ, err = wb:recv_frame()

    if wb.fatal then
      ngx.log(ngx.ERR, "WebSocket fatal error: ", err)
      break
    end

    if not data then
      local ok, err = wb:send_ping()
      if not ok then
        ngx.log(ngx.ERR, "Ping failed: ", err)
        break
      end

    elseif typ == "text" then
      local ok, err = irc.send(instance_id, data)
      if not ok then
        wb:send_text("IRC send error: " .. (err or "unknown"))
      end

    elseif typ == "ping" then
      wb:send_pong()

    elseif typ == "pong" then
      ngx.log(ngx.INFO, "Received pong")

    elseif typ == "close" then
      break
    end
  end

  -- On disconnect, gracefully shut down IRC
  irc.send(instance_id, "/quit")  -- 💬 Send /quit to IRC client
  irc.close(instance_id)          -- 🔌 Close socket and cleanup state
  wb:send_close()                 -- 📡 Finalize WebSocket
end

return _M
