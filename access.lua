local cjson = require("cjson")

local log = require("spp/utils/log")
local error_response = require("spp/utils/response").error_response

--- Access phase handler.
---@param ngx any The Nginx context
---@param auth_access any The custom auth access function 
---@return any The response object
local function access(ngx, auth_access)
  assert(ngx, "ngx is required")
  assert(auth_access, "auth_access is required")

  local host = ngx.var.host
  local api_key = nil
  local subdomains = nil

  log(ngx, "INFO", "access - host: " .. host .. "\nheaders: " .. cjson.encode(ngx.req.get_headers()))

  local parts = {}
  for part in host:gmatch("[^.]+") do
    table.insert(parts, part)
  end

  -- check if host contains "localhost"
  if host:find("localhost") then
    -- check if parts length is 1
    if #parts == 1 then
      return error_response(ngx, 400, "Invalid host " .. host)
    end
    api_key = parts[1]

    if #parts > 2 then
      subdomains = {}
      for i = 2, #parts do
        table.insert(subdomains, parts[i])
      end
      -- join subdomains
      subdomains = table.concat(subdomains, ".")
    end
  else
    -- check if parts length is 2
    if #parts == 2 then
      return error_response(ngx, 400, "Invalid host" .. host)
    end
    api_key = parts[1]

    if #parts > 3 then
      subdomains = {}
      for i = 2, #parts - 1 do
        table.insert(subdomains, parts[i])
      end
      -- join subdomains
      subdomains = table.concat(subdomains, ".")
    end
  end

  log(ngx, "INFO", "access - subdomains: " .. (subdomains or "nil"))

  return auth_access(ngx, api_key)
end

return access
