-- luacheck: globals ngx, allow defined
local inspect = require "lib.inspect"
local pgmoon = require "lib.pgmoon"
local pg = pgmoon.new({
  host = "db",
  port = "5432",
  database = "postgres",
  user = "postgres"
})

local ok, err = pg:connect()
if not ok then
  ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
  ngx.say("failed to connect to db: " .. err)
  return
end

local res, err = pg:query("select * from edwintask limit 100")
if not res then
  ngx.say("failed retrieving any records: " .. err)
end
ngx.say("<html><head><title>results</title></head><body><pre>")
ngx.say(inspect(res))
ngx.say("</pre></body></html>")

pg:keepalive()
