local mysql = require("resty.mysql")
local cjson = require("cjson")

local log = require("spp/utils/log")
local access_response = require("spp/utils/response").access_response
local error_response = require("spp/utils/response").error_response

local function make_connection(ngx, db_host, db_port, db_user, db_pass, db_name, charset, max_packet_size)
  local db, err = mysql:new()

  if not db then
    log(ngx, "ERROR", "failed to instantiate mysql: " .. err)
    return {
      res = error_response(ngx, 500, "Failed to instantiate mysql")
    }
  end

  db:set_timeout(2000) -- 1 sec
  local ok, err, errcode, sqlstate = db:connect {
    host = db_host,
    port = db_port,
    user = db_user,
    database = db_name,
    password = db_pass,
    charset = charset,
    max_packet_size = max_packet_size,
  }

  log(ngx, "INFO", "sql config:\n  host: '" .. db_host
    .. "'\n  port: '" .. db_port
    .. "'\n  user: '" .. db_user
    .. "'\n  password: '" .. db_pass
    .. "'\n  database: '" .. db_name
    .. "'\n  charset: '" .. charset
    .. "'\n  max_packet_size: '" .. max_packet_size .. "'")

  if not ok then
    log(ngx, "ERROR",
      (err or "failed to connect: nil") .. " - errcode: " .. (errcode or "nil") .. " - sqlstate: " .. (sqlstate or "nil"))
    return {
      response = error_response(ngx, 500, "Failed to connect to database"),
      db = nil
    }
  end

  log(ngx, "INFO", "Successfully connected to database");

  return {
    response = nil,
    db = db
  }
end

local function sql_access(ngx, api_key)
  assert(ngx, "ngx is required")
  assert(api_key, "api_key is required")

  -- ex: 127.0.0.1,3306,user,password,db_name,tb_name,utf8,1048576
  local sql_config = ngx.var.sql_config
  local parts = {}
  for part in sql_config:gmatch("[^,]+") do
    table.insert(parts, part)
  end

  -- check if parts length is 5
  if #parts < 5 then
    return error_response(ngx, 400, "Invalid sql_config length " .. #parts .. "\n" .. sql_config)
  end

  local db_host = parts[1]
  local db_port = tonumber(parts[2])
  local db_user = parts[3]
  local db_pass = parts[4] == "nil" and nil or parts[4]
  local db_name = parts[5]
  local charset = parts[7] or "utf8"
  local max_packet_size = parts[8] and tonumber(parts[8]) or (1024 * 1024)
  local sql_query = parts[9] or ("SELECT `wp_hosts`.`host` FROM `wp_tokens` LEFT JOIN `wp_hosts` ON `wp_tokens`.`host_id` = `wp_hosts`.`id` WHERE `wp_tokens`.`token` = <-api_key-> AND `wp_tokens`.`status` = 'active' AND `wp_tokens`.`expired_at` > NOW()")

  local result = make_connection(ngx, db_host, db_port, db_user, db_pass, db_name, charset, max_packet_size)

  if result.response or not result.db then
    return result.response
  end

  local db = result.db

  log(ngx, "INFO", "connected to mysql, reused_times: " .. db:get_reused_times() .. " sql_config: " .. sql_config)

  -- Replace placeholder with quoted api_key
  sql_query = string.gsub(sql_query, "<%-api_key%->", ngx.quote_sql_str(api_key))

  log(ngx, "INFO", "executing: " .. sql_query);

  local res, err, errcode, sqlstate = db:query(sql_query)

  log(ngx, "INFO", "res: " .. cjson.encode(res));

  if not res then
    log(ngx, "ERROR",
             "bad result: " .. (err or "nil")
             .. ": " .. (errcode or "nil") .. ": "
             .. (sqlstate or "nil")
             .. ". sql: " .. sql_query)
    return error_response(ngx, 500, "Failed to query database")
  end

  if #res == 0 then
    return error_response(ngx, 400, "Unauthorized\nAPI-KEY: " .. api_key)
  end

  return access_response(ngx, "Authorized", res[1]["host"])
end

return sql_access
