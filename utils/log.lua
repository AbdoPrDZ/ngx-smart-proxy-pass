--- Log a message to the log file or to the Nginx error log.
---@param ngx any The Nginx context
---@param level any The log level
---@param message any The message to log
local function log(ngx, level, message)
  local debug = ngx.var.spp_debug == "true"
  if debug then
    local log_path = ngx.var.log_path

    message = os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level .. "] " .. message

    local file = io.open(log_path, "a")
    if file then
      file:write(message .. "\n")
      file:close()
      return
    else
      ngx.log(ngx.ERR, "failed to open log file: " .. log_path)
    end

    ngx.log(ngx.ERR, message)
  end
end

return log
