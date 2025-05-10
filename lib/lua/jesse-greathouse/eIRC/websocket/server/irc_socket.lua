local cjson = require "cjson"
local socket = ngx.socket
local pipe = require "ngx.pipe"

local env = require "jesse-greathouse.eIRC.env"
local http = require "jesse-greathouse.eIRC.http"
local store = require "jesse-greathouse.eIRC.stores.irc_instance_store"

local _M = {}

-- Computes the full Unix socket path for a given IRC instance
local function get_socket_file(instance_id)
  return env.var_dir() .. "/socket/irc-client-" .. instance_id .. ".sock"
end

-- Spawns a new IRC client process unless already running for this instance
function _M.start_client(nick, realname, server, port, channels, instance_id, sasl_secret)
  if not (nick and server and port and channels and instance_id) then
    ngx.log(ngx.ERR, "Missing required IRC client parameters")
    return nil, "Missing parameters"
  end

  if store.running(instance_id) then
    return true
  end

  local socket_dir = env.var_dir() .. "/socket"
  local log_dir = env.log_dir() .. "/irc-client"
  local channels_str = ""

  if type(channels) == "table" then
    if #channels > 0 then
      channels_str = table.concat(channels, ",")
    end
  elseif type(channels) == "string" then
    channels_str = channels
  end

  local args = {
      env.bin_dir() .. "/irc-client",
      "--nick=" .. nick,
      "--realname=" .. realname,
      "--server=" .. server,
      "--port=" .. tostring(port),
      "--listen=" .. socket_dir,
      "--log=" .. log_dir,
      "--instance=" .. instance_id
  }

  -- Only add --channels if there are any to join
  if channels_str ~= "" then
    table.insert(args, "--channels=" .. channels_str)
  end

  if env.use_sasl() then
    table.insert(args, "--sasl")
  end

  local proc, err = pipe.spawn(args, {
    merge_stderr = true,
    detached = true,
  })

  if not proc then
    ngx.log(ngx.ERR, "Failed to spawn IRC client: ", err)
    return nil, err
  end

  store.set_running(instance_id, true)
  store.set_secret(instance_id, sasl_secret)
  store.set_realname(instance_id, realname)

  ngx.log(ngx.INFO, "IRC client spawned for instance_id ", instance_id)
  return true
end

-- Attempts to connect to the Unix socket for this instance
-- Reuses existing connection if already present
function _M.connect(instance_id)
  if not instance_id then
    ngx.log(ngx.ERR, "Missing instance_id in IRC socket connect")
    return nil
  end

  local existing = store.get_socket(instance_id)
  if existing then
    return existing
  end

  local sock = socket.tcp()
  local ok, err = sock:connect("unix:" .. get_socket_file(instance_id))

  if not ok then
    ngx.log(ngx.ERR, "IRC socket connection failed: ", err)
    return nil
  end

  ngx.log(ngx.INFO, "Connected to IRC socket for instance_id ", instance_id)
  store.set_socket(instance_id, sock)

  return sock
end

-- Attempts multiple connections to the IRC socket, retrying with delay
function _M.connect_with_retry(max_attempts, delay, instance_id)
  ngx.sleep(delay)

  for attempt = 1, max_attempts do
    local sock = _M.connect(instance_id)
    if sock then
      sock:settimeouts(0, 60000, 60000)
      return sock
    end
    ngx.sleep(delay)
  end

  ngx.log(ngx.ERR, "connect_with_retry(): Failed to connect after ", max_attempts, " attempts")
  return nil
end

-- Sends a line of IRC data over the instance socket
function _M.send(instance_id, line)
  local sock = store.get_socket(instance_id)
  if not sock then return nil, "not connected" end
  return sock:send(line .. "\n")
end

-- Begins a coroutine to pipe IRC output → WebSocket client
function _M.receive(instance_id, wb)
  local sock = store.get_socket(instance_id)
  if not sock then
    ngx.log(ngx.ERR, "Cannot start IRC receive loop: no socket for instance_id ", instance_id)
    return
  end

  if store.get_reader(instance_id) then
    ngx.log(ngx.WARN, "Receive loop already running for instance_id ", instance_id)
    return
  end

  store.set_running(instance_id, true)
  -- pull SASL flag & secret, and the realname username
  local use_sasl = env.use_sasl()
  local secret   = store.get_secret(instance_id) or ""
  local realname     = store.get_realname(instance_id) or instance_id

  store.set_reader(instance_id, ngx.thread.spawn(function()
    while store.running(instance_id) do
      local line, err = sock:receive("*l")

      if line then
        -- SASL handshake authentication if enabled
        if use_sasl then
          if line:match("^AUTHENTICATE%s*[:]?%+") then
            -- Server is asking for our PLAIN blob
            local raw = realname .. "\0" .. realname .. "\0" .. secret
            sock:send("/input AUTHENTICATE " .. ngx.encode_base64(raw) .. "\n")
          end
        else
          -- NickServ fallback for non-SASL
          if line:match("%s376%s") or line:match("%s422%s") then
            sock:send("/input PRIVMSG NickServ :IDENTIFY " .. secret .. "\n")
          end
        end

        local ok, send_err = wb:send_text(line)
        if not ok then
          ngx.log(ngx.INFO,
            "WebSocket no longer accepting messages for instance_id ",
            instance_id, ": ", send_err)
          break
        end

      elseif err == "timeout" then
        ngx.sleep(0.1)

      elseif err == "closed" then
        ngx.log(ngx.INFO,
          "IRC socket closed normally for instance_id ",
          instance_id)
        break

      else
        ngx.log(ngx.ERR,
          "IRC socket closed unexpectedly (", err,
          ") for instance_id ", instance_id)
        break
      end
    end
  end))
end

-- Closes socket + shuts down the receive loop for this instance
function _M.close(instance_id)
  store.stop(instance_id)

  local sock = store.get_socket(instance_id)
  if sock then
    sock:close()
    store.clear_socket(instance_id)
  end

  store.clear_reader(instance_id)
end

_M.get_socket_file = get_socket_file

return _M
