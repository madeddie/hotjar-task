-- luacheck: globals ngx, allow defined
local queue = require "./lua/rabbitmq"

ngx.req.read_body()
local args = ngx.req.get_body_data()
if not args or args == '' then
  ngx.status = ngx.HTTP_BAD_REQUEST
  ngx.say("no post data received")
  return
end

local ok, err = queue.send(args)
if not ok then
  ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
  ngx.say("failed to accept your message: " .. err)
  return
end
ngx.status = ngx.HTTP_ACCEPTED
ngx.say(ok)
