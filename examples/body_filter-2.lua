local log = require("spp.utils.log")

return function (ngx, header, body)
  local host = ngx.var.host
  local target_host = ngx.var.proxy_host
  local content_type = header["Content-Type"]

  log(ngx, "INFO", "body_filter - host: " .. host)
  log(ngx, "INFO", "body_filter - target_host: " .. target_host)

  local hostParts = {}
  for part in host:gmatch("[^.]+") do
    table.insert(hostParts, part)
  end

  if host:find("localhost") then
    host = table.concat({hostParts[#hostParts - 1], hostParts[#hostParts]}, '.')
  else
    host = table.concat({hostParts[#hostParts - 2], hostParts[#hostParts - 1], hostParts[#hostParts]}, '.')
  end

  log(ngx, "INFO", "body_filter - host: " .. host)

  local parts = {}
  for part in target_host:gmatch("[^.]+") do
    table.insert(parts, part)
  end

  target_host = table.concat({parts[#parts - 1], parts[#parts]}, '.')

  log(ngx, "INFO", "body_filter - target_host: " .. target_host)
  -- log(ngx, "INFO", "body_filter - chunk: " .. body)

  body = string.gsub(body, "https://www." .. target_host, "http://www." .. target_host)
  body = string.gsub(body, "https://" .. target_host, "http://" .. target_host)
  body = string.gsub(body, "www." .. target_host, host)
  body = string.gsub(body, target_host, host)

  return body
end