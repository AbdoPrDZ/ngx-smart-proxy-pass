local redisManager = require("resty.redis")

local error_response = require("spp/utils/response").error_response

return function (ngx)
  local redis_config = ngx.var.redis_config
  if not redis_config then
    return error_response(ngx, 500, "Redis config is not set"), nil
  end

  local parts = {}
  for part in string.gmatch(redis_config, "[^,]+") do
    table.insert(parts, part)
  end

  local host = parts[1] or "127.0.0.1"
  local port = tonumber(parts[2]) or 6379
  local timeout = tonumber(parts[3]) or 1000
  local redis = redisManager:new()

  redis:set_timeout(timeout)
  local ok, err = redis:connect(host, port)

  if not ok then
    return error_response(ngx, 500, "Failed to connect to Redis: " .. err), nil
  end

  return nil, redis
end
