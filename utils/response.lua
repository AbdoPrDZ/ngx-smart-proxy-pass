local log = require("spp/utils/log")

--- Return a response object for the access phase.
---@param ngx any The Nginx context
---@param success any The success status of the response
---@param message any The message to log
---@param target any The target object
local function response(ngx, success, message, target)
  assert(ngx, "ngx is reqired")
  assert(message, "message is required")

  log(ngx, success and "INFO" or "ERROR", "response - " .. message .. " - " .. (target or "nil"))

  return {
    success = success,
    message = message,
    target = target
  }
end

--- Return a response object for the access phase.
---@param ngx any The Nginx context
---@param message any The message to log
---@param target any The target object
local function access_response(ngx, message, target)
  assert(ngx, "ngx is reqired")
  assert(message, "message is required")
  assert(target, "target is required")

  log(ngx, "INFO" , "access_response - " .. message .. " - " .. target)

  return response(ngx, true, message, target)
end

--- Return an error response.
---@param ngx any The Nginx context
---@param status any The HTTP status code
---@param message any The message to log
---@return any The response object
local function error_response(ngx, status, message)
  assert(ngx, "ngx is reqired")
  assert(status, "status is required")
  assert(message, "message is required")

  log(ngx, "ERROR", "error_response - " .. message)

  ngx.status = status
  ngx.header.content_type = "text/plain"
  ngx.say(message)

  return response(ngx, false, message)
end

return {
  access_response = access_response,
  error_response = error_response
}
