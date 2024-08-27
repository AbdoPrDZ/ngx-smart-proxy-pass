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

  local payload_token = jwt_obj.payload.token
  if payload_token == nil then
    return nil, error_response(ngx, 400, "token is required in JWT payload")
  end

  local payload_host = jwt_obj.payload.host
  if payload_host == nil then
    return nil, error_response(ngx, 400, "host is required in JWT payload")
  end

  log(ngx, "INFO", "JWT token verified\n  payload_host: " .. payload_host)

  ngx.var.cookie_value = jwt_obj.payload.cookie or ""

  log(ngx, "INFO", "jwt_verify - \n  ngx.var.cookie_value: " .. ngx.var.cookie_value)

  return payload_host, nil
end

local function filter_args(ngx, args, api_key)
  local filtered_args = {}
  for key, value in pairs(args) do
    if key ~= api_key then
      if type(value) == "table" then
        for _, v in ipairs(value) do
          table.insert(filtered_args, ngx.escape_uri(key) .. "=" .. ngx.escape_uri(v))
        end
      else
        table.insert(filtered_args, ngx.escape_uri(key) .. "=" .. ngx.escape_uri(value))
      end
    end
  end
  return table.concat(filtered_args, "&")
end

return function (ngx, api_key)
  local client_ip = ngx.var.remote_addr

  log(ngx, "INFO", "client_ip: " .. client_ip .. ", api_key: " .. api_key)

  local err, redis = connect_redis(ngx)
  if err then
    return err
  end

  local args = ngx.req.get_uri_args()
  local jwt_token = args[api_key]

  if jwt_token then
    local payload_host, res_err = verify_jwt(ngx, jwt_token)
    if res_err then
      return res_err
    end

    -- store data as {api_key: {client_ip-1: kwt_token-1, client_ip-2: kwt_token-2}}
    local ok, redi_err = redis:hset('wp-spp-hosts:' .. api_key, client_ip, jwt_token)
    if not ok then
      return error_response(ngx, 500, "Failed to store data in Redis: " .. redi_err)
    end

    -- Set expiration time for the key (e.g., 3600 seconds)
    local ttl = 3600
    local expire_ok, expire_err = redis:expire('wp-spp-hosts:' .. api_key, ttl)
    if not expire_ok then
      return error_response(ngx, 500, "Failed to set expiration time for Redis key: " .. expire_err)
    end

    -- filter out the api_key from the
    local filtered_args = filter_args(ngx, args, api_key)
    ngx.req.set_uri_args(filtered_args)

    return access_response(ngx, "Authorized", payload_host)
  else
    -- check if the client_ip is in the redis
    local jwt_token, err = redis:hget('wp-spp-hosts:' .. api_key, client_ip)
    if not jwt_token then
      return error_response(ngx, 401, "Unauthorized access")
    end

    local payload_host, jwy_err = verify_jwt(ngx, jwt_token)
    if jwy_err then
      return jwy_err
    end

    return access_response(ngx, "Authorized", payload_host)
  end
end
