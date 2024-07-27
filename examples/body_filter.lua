local log = require("spp/utils/log")
local zlib = require("zlib")

-- local function decode_gzip(ngx, data)
--   local status, stream = pcall(zlib.inflate)
--   if not status then
--     log(ngx, "ERROR", "Failed to initialize zlib inflate: " .. stream)
--     return nil
--   end

--   local status, decompressed = pcall(stream, data, "finish")
--   if not status then
--     log(ngx, "ERROR", "Failed to decompress data: " .. decompressed)
--     return nil
--   end

--   return decompressed
-- end

-- local function encode_gzip(data)
--   local status, stream = pcall(zlib.deflate)
--   if not status then
--     log(ngx, "ERROR", "Failed to initialize zlib deflate: " .. stream)
--     return nil
--   end

--   local status, compressed = pcall(stream, data, "finish")
--   if not status then
--     log(ngx, "ERROR", "Failed to compress data: " .. compressed)
--     return nil
--   end

--   return compressed
-- end

local function body_filter(ngx, body)
  local host = ngx.var.host
  local target_host = ngx.var.proxy_host
  local is_gzip = ngx.header["Content-Encoding"] and ngx.header["Content-Encoding"]:find("gzip")

  log(ngx, "INFO", "body_filter - Content-Type: " .. (ngx.header["Content-Type"] or "nil"))
  log(ngx, "INFO", "body_filter - Content-Encoding: " .. (ngx.header["Content-Encoding"] or "nil"))
  log(ngx, "INFO", "body_filter - is_gzip: " .. (is_gzip and "true" or "false"))

  log(ngx, "INFO", "body_filter - host: " .. host)
  log(ngx, "INFO", "body_filter - target_host: " .. target_host)


  if not body or target_host == nil or target_host == "" then
    return body
  end

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

  -- if is_gzip then
  --   body = decode_gzip(body)
  --   if not body then
  --     log(ngx, "ERROR", "Failed to decode gzip data")
  --     return body -- Return the original data if decoding fails
  --   end
  --   -- ngx.header["Content-Encoding"] = ""
  -- else
  --   body = body
  -- end

  log(ngx, "INFO", "find https " .. (body:find("https") or "nil"))

  body = string.gsub(body, "https:" .. target_host, "http:" .. target_host)
  body = string.gsub(body, "www." .. target_host, host)
  body = string.gsub(body, target_host, host)

  -- if is_gzip then
  --   body = encode_gzip(body)
  --   if not body then
  --     log(ngx, "ERROR", "Failed to encode gzip data")
  --     return body -- Return the original data if encoding fails
  --   end
  --   ngx.header["Content-Encoding"] = "gzip"  -- Ensure Content-Encoding is set correctly
  -- else
  --   ngx.header["Content-Encoding"] = "html"  -- Remove Content-Encoding header if the content is not gzipped
  -- end

  log(ngx, "INFO", "filtered_data: " .. body)

  return body
end

return body_filter
