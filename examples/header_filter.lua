local log = require("spp/utils/log")

return function(ngx)
  local host = ngx.var.host
  local target_host = ngx.var.proxy_host

  log(ngx, "INFO", "header_filter - Location: " .. (ngx.header["Location"] or "nil"))

  local hostParts = {}
  for part in host:gmatch("[^.]+") do
    table.insert(hostParts, part)
  end

  if host:find("localhost") then
    host = table.concat({hostParts[#hostParts - 1], hostParts[#hostParts]}, '.')
  else
    host = table.concat({hostParts[#hostParts - 2], hostParts[#hostParts - 1], hostParts[#hostParts]}, '.')
  end

  local parts = {}
  for part in target_host:gmatch("[^.]+") do
    table.insert(parts, part)
  end

  target_host = table.concat({parts[#parts - 1], parts[#parts]}, '.')

  -- filter location header
  if ngx.header["Location"] then
    ngx.log(ngx.ERR, 'replace location header')
    ngx.header["Location"] = string.gsub(ngx.header["Location"], "https://", "http://")
    ngx.header["Location"] = string.gsub(ngx.header["Location"], "https%%3A%%2F%%2", "http%%3A%%2F%%2")
    ngx.header["Location"] = string.gsub(ngx.header["Location"], "www." .. target_host, host)
    ngx.header["Location"] = string.gsub(ngx.header["Location"], target_host, host)
    ngx.log(ngx.ERR, 'replace location header end')
  end
end
