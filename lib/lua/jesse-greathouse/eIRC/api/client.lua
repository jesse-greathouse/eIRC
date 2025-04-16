local resty_http = require "resty.http"
local cjson = require "cjson"
local env = require "jesse-greathouse.eIRC.env"

local _M = {}

-- Generic HTTP request handler
local function send_request(method, endpoint, body)
    local base_url = env.app_url()
    if not base_url then
        return nil, "Missing APP_URL"
    end

    local httpc = resty_http.new()
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

    return true
end

function _M.get(endpoint) return send_request("GET", endpoint) end
function _M.post(endpoint, body) return send_request("POST", endpoint, body) end
function _M.put(endpoint, body) return send_request("PUT", endpoint, body) end
function _M.delete(endpoint) return send_request("DELETE", endpoint) end

function _M.get_user_by_token(token)
    return _M.get("/api/auth/user/" .. token)
end

return _M
