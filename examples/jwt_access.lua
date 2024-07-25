local jwt = require("resty.jwt")
local cjson = require("cjson")

local log = require("spp/utils/log")
local access_response = require("spp/utils/response").access_response
local error_response = require("spp/utils/response").error_response

return function (ngx, jwt_token)
  local jwt_secret = ngx.var.jwt_secret
  local jwt_obj = jwt:verify(jwt_secret, jwt_token)
  if jwt_obj.verified == false then
    return error_response(ngx, 401, "Invalid JWT token")
  end

  log(ngx, "INFO", "JWT token verified\n  payload: " .. cjson.encode(jwt_obj.payload))

  local target_host = jwt_obj.payload.target_host

  if target_host == nil then
    return error_response(ngx, 400, "target_host is required in JWT payload")
  end

  log(ngx, "INFO", "JWT token verified\n  target_host: " .. target_host)

  return access_response(ngx, "Authorized", target_host)
end