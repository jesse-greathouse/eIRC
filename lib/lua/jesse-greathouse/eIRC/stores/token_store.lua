local _M = {}

-- Shared dictionary used for one-time token binding
local bindings = ngx.shared.token_binding

--[[
    get_binding(token)

    Binds a one-time chat token to the current request's instance ID,
    or validates that the token is already bound to this specific instance.

    Purpose:
      - Prevents token reuse across multiple connections
      - Ensures tokens can only be used by the instance that claimed them

    Parameters:
      - token: short-lived token from the frontend (e.g. ?chat_token=abc)

    Logic:
      1. Retrieve the current request ID from Nginx
      2. If no token is provided, return an error
      3. If the token is already bound to a different instance, reject it
      4. Otherwise bind the token to this instance for 180 seconds
      5. Return true if binding is valid or newly created
--]]
function _M.get_binding(token)
    local instance_id = ngx.var.request_id

    -- Reject if no token was supplied
    if not token then
        return nil, "Missing token"
    end

    -- Check if the token is already bound
    local existing = bindings:get(token)

    -- Reject if token is bound to a different instance
    if existing and existing ~= instance_id then
        return nil, "Token binding mismatch"
    end

    -- Bind the token to the current instance for 180 seconds (3 min)
    bindings:set(token, instance_id, 180)

    -- Token is either freshly bound or valid — allow access
    return true
end

return _M
