local log = require("spp/utils/log")
local error_response = require("spp/utils/response").error_response

local auth_access = require("spp/auth_access")
local local_access = require("spp/local_access")

--- Access phase handler.
---@param ngx any The Nginx context
---@param access_host any The access host
---@param auth_json_path any The path to the auth JSON file
---@return any The response object
local function access(ngx, access_host, auth_json_path)
  assert(ngx, "ngx is required")
  if not access_host then
    assert(auth_json_path, "auth_json_path is required")
  else
    assert(access_host, "access_host is required")
  end

  local host = ngx.var.host
  local api_key = nil
  local subdomains = nil

  log(ngx, "INFO", "access - host: " .. host)

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

  if access_host then
    return auth_access(ngx, access_host, api_key)
  end

  return local_access(ngx, auth_json_path, api_key)
end

return access
