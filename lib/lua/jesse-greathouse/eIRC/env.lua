local _M = {}

function _M.irc_host()
    return os.getenv("IRC_SERVER_HOST") or "127.0.0.1"
end

function _M.irc_port()
    return tonumber(os.getenv("IRC_SERVER_PORT")) or 6667
end

function _M.app_url()
    local url = os.getenv("APP_URL")
    return url and url:gsub("/+$", "") or nil
end

return _M
