--- Log a message to the log file or to the Nginx error log.
---@param ngx any The Nginx context
---@param level any The log level
---@param message any The message to log
local function log(ngx, level, message)
  local log_path = ngx.var.log_path

  message = os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level .. "] " .. message

  local file = io.open(log_path, "a")
  if file then
    file:write(message .. "\n")
    file:close()
    return
  end
  ngx.log(ngx.ERR, message)

end

return log
