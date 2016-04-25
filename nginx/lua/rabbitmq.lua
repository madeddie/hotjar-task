-- luacheck: globals ngx, allow defined
local M = {}
-- local cjson = require "cjson"
local rabbitmq = require "lib.rabbitmqstomp"
local inspect = require "lib.inspect"

local opts = { username = "guest",
               password = "guest",
               vhost = "/" }

function M.send(msg)
  local mq, _ = rabbitmq:new(opts)
  mq:set_timeout(10000)
  local ok, err = mq:connect("queue", 61613) 
  if not ok then
    local errmsg = "error connecting to MQ: " .. err
    ngx.log(ngx.INFO, errmsg)
    return nil, errmsg
  end

  local headers = {}
  headers["destination"] = "/queue/edwintask"
  headers["persistent"] = "true"
  
  ok, err = mq:send(inspect(msg), headers)
  if not ok then
    local errmsg = "error publishing msg: " .. err
    ngx.log(ngx.INFO, errmsg)
    return nil, errmsg
  end
  okmsg = "published: " .. inspect(msg)
  ngx.log(ngx.INFO, okmsg)
  mq:set_keepalive(10000, 10000)
  return okmsg, nil
end

return M
