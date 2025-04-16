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

-- Generic HTTP request handler
local function send_request(method, endpoint, body)
    local base_url, err = get_app_url()
    if not base_url then return nil, err end

    local httpc = http.new()
    local opts = {
        method = method,
        headers = {
            ["Accept"] = "application/json",
        }
    }

    if body then
        opts.headers["Content-Type"] = "application/json"
        opts.body = cjson.encode(body)
    end

    local res, err = httpc:request_uri(base_url .. endpoint, opts)

    if not res then
        return nil, "API request failed: " .. (err or "unknown error")
    end

    if res.status < 200 or res.status >= 300 then
        return nil, "API returned status " .. res.status .. ": " .. (res.body or "")
    end

    if res.body and res.body ~= "" then
        local ok, decoded = pcall(cjson.decode, res.body)
        if not ok then
            return nil, "Failed to decode JSON: " .. tostring(res.body)
        end
        return decoded
    end

    return true  -- Return true for empty success response (e.g., DELETE 204)
end

-- GET request
function _M.get(endpoint)
    return send_request("GET", endpoint)
end

-- POST with JSON body
function _M.post(endpoint, body)
    return send_request("POST", endpoint, body)
end

-- PUT with JSON body
function _M.put(endpoint, body)
    return send_request("PUT", endpoint, body)
end

-- DELETE request (usually no body)
function _M.delete(endpoint)
    return send_request("DELETE", endpoint)
end

-- Specific alias using the generic `get` under the hood
function _M.get_user_by_token(token)
    return _M.get("/api/auth/user/" .. token)
end

return _M
