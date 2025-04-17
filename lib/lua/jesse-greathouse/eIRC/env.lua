local _M = {}

-- IRC server connection config
function _M.irc_host()
    return os.getenv("IRC_SERVER_HOST") or "127.0.0.1"
end

function _M.irc_port()
    return tonumber(os.getenv("IRC_SERVER_PORT")) or 6667
end

-- Application base URL
function _M.app_url()
    local url = os.getenv("APP_URL")
    return url and url:gsub("/+$", "") or nil
end

-- File system paths
function _M.var_dir()
    return os.getenv("VAR") or "/tmp/eirc/var"
end

function _M.log_dir()
    return os.getenv("LOG_DIR") or _M.var_dir() .. "/log"
end

function _M.bin_dir()
    return os.getenv("BIN") or "/usr/local/bin"
end

return _M
