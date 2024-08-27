local jwt = require("resty.jwt")
local cjson = require("cjson")

local log = require("spp/utils/log")
local access_response = require("spp/utils/response").access_response
local error_response = require("spp/utils/response").error_response
local connect_redis = require("spp/utils/connect_redis")

local function verify_jwt(ngx, jwt_token)
  local jwt_secret = ngx.var.jwt_secret
  if not jwt_secret then
    return error_response(ngx, 500, "JWT secret is not set")
  end

  if not jwt_token then
    return error_response(ngx, 400, "JWT token is required")
  end

  local jwt_obj = jwt:verify(jwt_secret, jwt_token)
  if jwt_obj.verified == false then
    -- return nil, error_response(ngx, 401, "Invalid JWT token\ntoken: " .. (jwt_token or "nil") .. "\nerror: " .. jwt_obj.reason)
    return nil, error_response(ngx, 401, "Invalid JWT token")
  end

  log(ngx, "INFO", "JWT token verified\n  payload: " .. cjson.encode(jwt_obj.payload))

  return jwt_obj.payload
end

return function (ngx, api_key)
  local remoteAddress = ngx.var.remote_addr

  -- split api_key to get the actual key and uid (e.g: APIKEY_UID)
  local api_key_parts = {}
  for part in string.gmatch(api_key, "([^_]+)") do
    table.insert(api_key_parts, part)
  end

  if #api_key_parts < 2 then
    return error_response(ngx, 400, "Invalid API key")
  end

  api_key = api_key_parts[1]
  local uid = api_key_parts[2]

  log(ngx, "INFO", "uid: " .. uid .. ", remoteAddress: " .. remoteAddress .. ", api_key: " .. api_key)

  local redis_err, redis = connect_redis(ngx)
  if redis_err then
    return redis_err
  end

  -- get the user by uid and verify
  local user, user_err = redis:hgetall("wp-spp-hosts:" .. uid)
  if user_err or user == ngx.null or #user == 0 then
    return error_response(ngx, 401, "Undefined user " .. tostring(user))
  else
    log(ngx, "INFO", "user: " .. cjson.encode(user))
  end

  local isConnected, con_err = redis:hget("wp-spp-hosts:" .. uid, 'connected')
  if con_err or isConnected == ngx.null or not isConnected then
    return error_response(ngx, 401, "The user is not connected " .. tostring(isConnected))
  end

  local uip, uip_err = redis:hget("wp-spp-hosts:" .. uid, 'uip')
  if uip_err or uip == ngx.null then
    return error_response(ngx, 401, "Undefined user IP address")
  end

  if uip ~= remoteAddress then
    return error_response(ngx, 401, "Invalid user IP address " .. tostring(uip))
  end

  local jwt_token, jwt_err = redis:hget("wp-spp-hosts:" .. uid, 'selected_token')
  if jwt_err then
    return error_response(ngx, 401, "Unauthorized access")
  end

  if jwt_token == ngx.null or #jwt_token == 0 then
    return error_response(ngx, 401, "There is no selected token")
  end

  log(ngx, "INFO", "jwt_token: " .. (jwt_token or "nil"))

  local jwt_payload, jwy_err = verify_jwt(ngx, jwt_token)
  if not jwt_payload then
    return jwy_err
  end

  if jwt_payload.token == nil or jwt_payload.token ~= api_key then
    return nil, error_response(ngx, 400, "Invalid token in JWT payload")
  end

  if jwt_payload.host == nil then
    return nil, error_response(ngx, 400, "host is required in JWT payload")
  end

  log(ngx, "INFO", "JWT token verified - payload_host: " .. jwt_payload.host)

  ngx.var.cookie_value = jwt_payload.cookie or ""

  log(ngx, "INFO", "jwt_verify - ngx.var.cookie_value: " .. ngx.var.cookie_value)

  return access_response(ngx, "Authorized", jwt_payload.host)
end
