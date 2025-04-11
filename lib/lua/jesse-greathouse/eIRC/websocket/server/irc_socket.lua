local socket = ngx.socket
local pipe = require "ngx.pipe"

local _M = {}

-- Per-instance state
local sockets = {}       -- instance_id -> socket
local is_running = {}    -- instance_id -> boolean
local readers = {}       -- instance_id -> thread

-- Starts an IRC client process if not already started
function _M.start_client(nick, server, port, channels, instance_id)
  if not (nick and server and port and channels and instance_id) then
    ngx.log(ngx.ERR, "Missing required IRC client parameters")
    return nil, "Missing parameters"
  end

  if is_running[instance_id] then
    return true
  end

  local socket_path = os.getenv("VAR") .. "/socket/irc-client-" .. instance_id .. ".sock"
  local log_path = os.getenv("LOG_DIR") .. "/irc-client/" .. instance_id .. ".log"

  local args = {
    os.getenv("BIN") .. "/irc-client",
    "--nick=" .. nick,
    "--server=" .. server,
    "--port=" .. tostring(port),
    "--channels=" .. channels,
    "--listen=" .. socket_path,
    "--log=" .. log_path,
    "--instance=" .. instance_id
  }

  local proc, err = pipe.spawn(args, {
    merge_stderr = true,
    detached = true,
  })

  if not proc then
    ngx.log(ngx.ERR, "Failed to spawn IRC client: ", err)
    return nil, err
  end

  ngx.log(ngx.INFO, "IRC client spawned with instance_id ", instance_id)
  is_running[instance_id] = true
  return true
end

-- Internal connect helper; reuses existing socket if connected
function _M.connect(instance_id)
  if not instance_id then
    ngx.log(ngx.ERR, "Missing instance_id in connect")
    return nil
  end

  if sockets[instance_id] then
    return sockets[instance_id]
  end

  local socket_path = os.getenv("VAR") .. "/socket/irc-client-" .. instance_id .. ".sock"
  local sock = socket.tcp()
  local ok, err = sock:connect("unix:" .. socket_path)

  if not ok then
    ngx.log(ngx.ERR, "Failed to connect to IRC socket: ", err)
    return nil
  end

  ngx.log(ngx.INFO, "Connected to IRC socket for instance_id ", instance_id)
  sockets[instance_id] = sock
  return sock
end

-- Retry connect logic, encapsulated inside module
function _M.connect_with_retry(max_attempts, delay, instance_id)
  for attempt = 1, max_attempts do
    ngx.log(ngx.INFO, "Attempting IRC socket connection, try #", attempt)
    local sock = _M.connect(instance_id)
    if sock then
      sock:settimeouts(0, 60000, 60000)
      return sock
    end
    ngx.sleep(delay)
  end
  return nil
end

-- Send a message over the per-instance socket
function _M.send(instance_id, line)
  local sock = sockets[instance_id]
  if not sock then return nil, "not connected" end
  return sock:send(line .. "\n")
end

-- Start the receive loop for the instance's socket
function _M.receive(instance_id, wb)
  local sock = sockets[instance_id]
  if not sock then
    ngx.log(ngx.ERR, "Cannot receive: IRC socket is nil for instance_id ", instance_id)
    return
  end

  if readers[instance_id] then
    ngx.log(ngx.WARN, "Receive loop already started for instance_id ", instance_id)
    return
  end

  -- controls the flow of the while loop. Stops the thread if the websocket is closed.
  is_running[instance_id] = true

  readers[instance_id] = ngx.thread.spawn(function()
    while is_running[instance_id] do
      local line, err = sock:receive("*l")

      if line then
        local ok, send_err = wb:send_text(line)
        if not ok then
          ngx.log(ngx.INFO, "WebSocket no longer accepting messages for instance_id ", instance_id, ": ", send_err)
          break
        end

      elseif err == "timeout" then
        ngx.sleep(0.1)

      elseif err == "closed" then
        ngx.log(ngx.INFO, "IRC socket closed normally for instance_id ", instance_id)
        break

      else
        ngx.log(ngx.ERR, "IRC socket closed unexpectedly (", err, ") for instance_id ", instance_id)
        break
      end
    end
  end)
end

function _M.close(instance_id)
  is_running[instance_id] = false  -- 💡 This will stop the receive loop

  if sockets[instance_id] then
    sockets[instance_id]:close()
    sockets[instance_id] = nil
  end

  readers[instance_id] = nil
end

return _M
