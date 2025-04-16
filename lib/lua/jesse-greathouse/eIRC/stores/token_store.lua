local _M = {}

local bindings = ngx.shared.token_binding

function _M.get_binding(token)
    local instance_id = ngx.var.request_id

    if not token then
        return nil, "Missing token"
    end

    local existing = bindings:get(token)
    if existing and existing ~= instance_id then
        return nil, "Token binding mismatch"
    end

    bindings:set(token, instance_id, 180)
    return true
end

return _M
