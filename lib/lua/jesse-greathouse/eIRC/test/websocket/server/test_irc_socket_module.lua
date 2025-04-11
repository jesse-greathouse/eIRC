local function assert_module_table(module_path)
  local ok, mod = pcall(require, module_path)

  if not ok then
    error("Module '" .. module_path .. "' failed to load:\n" .. tostring(mod), 2)
  end

  if type(mod) ~= "table" then
    error("Module '" .. module_path .. "' did not return a table (got " .. type(mod) .. ")", 2)
  end

  print("✅ Module '" .. module_path .. "' loaded successfully and returned a table.")
end

-- Run the test
assert_module_table("jesse-greathouse.eIRC.websocket.server.irc_socket")
