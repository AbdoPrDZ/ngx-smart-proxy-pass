local log = require("spp/utils/log")

--- Return a response object for the access phase.
---@param ngx any The Nginx context
---@param success any The success status of the response
---@param message any The message to log
---@param target any The target object
local function access_response(ngx, success, message, target)
  log(ngx, "INFO", "access_response - " .. message .. " - " .. (target or "nil"))
  return {
    success = success,
    message = message,
    target = target
  }
end

--- Return an error response.
---@param ngx any The Nginx context
---@param status any The HTTP status code
---@param message any The message to log
---@return any The response object
local function error_response(ngx, status, message)
  log(ngx, "ERROR", "error_response - " .. message)
  ngx.status = status
  ngx.header.content_type = "text/plain"
  ngx.say(message)
  return access_response(ngx, false, message)
end

return {
  access_response = access_response,
  error_response = error_response
}
