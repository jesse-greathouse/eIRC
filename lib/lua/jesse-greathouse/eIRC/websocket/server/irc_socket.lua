local socket = ngx.socket
local pipe = require "ngx.pipe"

local _M = {}
local irc_socket = nil
local is_running = false

local config = {
  executable  = os.getenv("BIN")      .. "/irc-client",
  socket_path = os.getenv("VAR")      .. "/socket/irc-client.sock",
  log_path    = os.getenv("LOG_DIR")  .. "/irc-client.log"
}

function _M.start_client(nick, server, port, channels)
  if not (nick and server and port and channels) then
    ngx.log(ngx.ERR, "Missing required IRC client parameters")
    return nil, "Missing parameters"
  end

  if is_running then return true end

  local args = {
    config.executable,
    "--nick=" .. nick,
    "--server=" .. server,
    "--port=" .. tostring(port),
    "--channels=" .. channels,
    "--listen=" .. config.socket_path,
    "--log=" .. config.log_path
  }

  local proc, err = pipe.spawn(args, {
    merge_stderr = true,
    detached = true,
  })

  if not proc then
    ngx.log(ngx.ERR, "Failed to spawn IRC client: ", err)
    return nil, err
  end

  ngx.log(ngx.INFO, "IRC client spawned")
  is_running = true
  return true
end

function _M.connect()
  if irc_socket then return irc_socket end

  local sock = socket.tcp()
  local ok, err = sock:connect("unix:" .. config.socket_path)
  if not ok then
    ngx.log(ngx.ERR, "Failed to connect to IRC socket: ", err)
    return nil
  end

  ngx.log(ngx.INFO, "Connected to IRC socket")
  irc_socket = sock
  return sock
end

function _M.send(line)
  if not irc_socket then return nil, "not connected" end
  return irc_socket:send(line .. "\n")
end

function _M.receive(wb)
  if not irc_socket then
    ngx.log(ngx.ERR, "Cannot receive: IRC socket not connected")
    return
  end

  local function read_loop()
    while true do
      local line, err, partial = irc_socket:receive("*l")
      if line then
        local ok, send_err = wb:send_text(line)
        if not ok then
          ngx.log(ngx.ERR, "Failed to send to WebSocket: ", send_err)
          break
        end
      elseif err == "timeout" then
        ngx.sleep(0.1)
      else
        ngx.log(ngx.ERR, "IRC socket closed or error: ", err)
        break
      end
    end
  end

  ngx.thread.spawn(read_loop)
end

return _M
