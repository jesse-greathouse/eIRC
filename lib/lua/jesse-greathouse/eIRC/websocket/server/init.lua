-- lib/lua/jesse-greathouse/eIRC/websocket/server/init.lua
local _M = {}
local server = require "resty.websocket.server"
local irc = require "jesse-greathouse.eIRC.websocket.server.irc_socket"

function _M.run(nick, server_addr, port, channels)
  if not nick or type(nick) ~= "string" or nick == "" or
     not server_addr or type(server_addr) ~= "string" or server_addr == "" or
     not port or type(port) ~= "number" or
     not channels or type(channels) ~= "string" or channels == "" then
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

  local ok, err = irc.start_client(nick, server_addr, port, channels)
  if not ok then
    wb:send_text("IRC client startup failed: " .. (err or "unknown error"))
    return ngx.exit(444)
  end

  ngx.sleep(1.0)
  local sock = irc.connect()
  if not sock then
    wb:send_text("IRC socket connection failed")
    return ngx.exit(444)
  end

  irc.receive(wb)

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
      local ok, err = irc.send(data)
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

  wb:send_close()
end

return _M
