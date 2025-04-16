local http = require "resty.http"
local cjson = require "cjson"

local _M = {}

-- Gets the base URL from Nginx environment variables
local function get_app_url()
    local url = ngx.var.APP_URL
    if not url or url == "" then
        ngx.log(ngx.ERR, "❌ APP_URL environment variable is missing or empty")
        return nil, "Missing APP_URL"
    end
    return url:gsub("/+$", "")
end

-- Generic GET request that returns a decoded Lua object
function _M.get(endpoint)
    local base_url, err = get_app_url()
    if not base_url then return nil, err end

    local httpc = http.new()
    local res, err = httpc:request_uri(base_url .. endpoint, {
        method = "GET",
        headers = { ["Accept"] = "application/json" }
    })

    if not res then
        return nil, "API request failed: " .. (err or "unknown error")
    end

    if res.status ~= 200 then
        return nil, "API returned status " .. res.status .. ": " .. (res.body or "")
    end

    local ok, decoded = pcall(cjson.decode, res.body)
    if not ok then
        return nil, "Failed to decode JSON: " .. tostring(res.body)
    end

    return decoded
end

-- Specific alias using the generic `get` under the hood
function _M.get_user_by_token(token)
    return _M.get("/api/auth/user/" .. token)
end

return _M
