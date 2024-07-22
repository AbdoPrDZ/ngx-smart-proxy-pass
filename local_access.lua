local cjson = require("cjson")

local indexOf = require("spp/utils/init").indexOf
local log = require("spp/utils/log")
local error_response = require("spp/utils/response").error_response
local access_response = require("spp/utils/response").access_response

--- Local access phase handler.
---@param ngx any The Nginx context
---@param auth_json_path any The path to the auth JSON file
---@param api_key any The API key
local function local_access(ngx, auth_json_path, api_key)
  log(ngx, "INFO", "local_access - api_key: " .. api_key .. " - auth_json_path: " .. auth_json_path)

  log(ngx, "INFO", "Attempting to open file: " .. auth_json_path)
  local file, rerr = io.open(auth_json_path, "r")
  if file == nil then
    log(ngx, "ERROR", "Failed to open auth file: " .. (rerr or "unknown error"))
    return error_response(ngx, 500, "Failed to open auth file")
  end

  local content = file:read("*a")
  file:close()

  local auth, err = cjson.decode(content)
  if not auth then
    log(ngx, "ERROR", "Failed to decode auth file: " .. (err or "unknown error"))
    return error_response(ngx, 500, "Failed to decode auth file")
  end

  if not auth[api_key] then
    return error_response(ngx, 400, "Unauthorized\nAPI-KEY: " .. api_key)
  end

  return access_response(ngx, true, "Authorized", auth[api_key]["target_host"])
end

return local_access
