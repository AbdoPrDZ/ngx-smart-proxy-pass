local httpc = require("resty.http").new()
local cjson = require("cjson")

local log = require("spp/utils/log")
local access_response = require("spp/utils/response").access_response
local error_response = require("spp/utils/response").error_response

--- Authenticate the request.
---@param ngx any The Nginx context
---@param auth_end_point any The auth end point
---@param api_key any The API key
---@return any The response object
local function auth_access(ngx, auth_end_point, api_key)
  log(ngx, "INFO", "auth_access - api_key: " .. api_key)

  local body = "{\"API-KEY\": \"" .. api_key .. "\"}"
  local res, err = nil, nil
  if not pcall(
    function()
      res, err = httpc:request_uri(auth_end_point, {
        method = "POST",
        body = body,
        headers = {
          ["Accept"] = "application/json",
          ["Content-Type"] = "application/json",
          ["content-length"] = tostring(#body)
        },
      })
    end
  ) then
    return error_response(ngx, 500, "Failed to request auth server")
  end
  if not res then
    return error_response(ngx, 500, err)
  end

  log(ngx, "INFO", "auth_access - response: " .. res.body)

  local response = {}

  if not pcall(
    function()
      response = cjson.decode(res.body)
    end
    ) then
    return error_response(ngx, 500, "Invalid response from auth server\nbody: " .. res.body)
  end

  if response.success then
    if not response.target then
      return error_response(ngx, 500, "Invalid response from auth server\nbody: " .. res.body)
    end
    return access_response(ngx, true, "Authorized", response.target)
  else
    return error_response(ngx, res.status, response.message or "Unauthorized")
  end
end

return auth_access
