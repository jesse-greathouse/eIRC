local _M = {
  sockets     = {},      -- instance_id → socket
  readers     = {},      -- instance_id → coroutine
  is_running  = {},      -- instance_id → boolean
  secrets     = {},      -- instance_id → SASL secret
  realnames   = {},      -- instance_id → IRC realname
}

-- Socket
function _M.get_socket(id) return _M.sockets[id] end
function _M.set_socket(id, sock) _M.sockets[id] = sock end
function _M.clear_socket(id) _M.sockets[id] = nil end

-- Reader coroutine
function _M.get_reader(id) return _M.readers[id] end
function _M.set_reader(id, reader) _M.readers[id] = reader end
function _M.clear_reader(id) _M.readers[id] = nil end

-- Running flag
function _M.running(id) return _M.is_running[id] == true end
function _M.set_running(id, value) _M.is_running[id] = value end
function _M.stop(id) _M.is_running[id] = false end

function _M.set_realname(id, realname)
  _M.realnames[id] = realname
end

function _M.get_realname(id)
  return _M.realnames[id]
end

function _M.clear_realname(id)
  _M.realnames[id] = nil
end

function _M.set_secret(id, secret)
  _M.secrets[id] = secret
end

function _M.get_secret(id)
  return _M.secrets[id]
end

function _M.clear_secret(id)
  _M.secrets[id] = nil
end

function _M.clear_all(id)
  _M.clear_socket(id)
  _M.clear_reader(id)
  _M.clear_realname(id)
  _M.clear_secret(id)
  _M.stop(id)
end

return _M
