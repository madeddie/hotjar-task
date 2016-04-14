-- luacheck: globals ngx, allow defined
ngx.req.read_body()
local args, err = ngx.req.get_post_args()
if not args then
  ngx.say("failed to get post args: ", err)
  return
end

if args == '' or next(args) == nil then
  ngx.say("no post args received, try posting key `msg` with any string as value")
end

-- TODO: test for msg key
-- TODO: sanity check input
-- TODO: write msg value to MQ
for key, val in pairs(args) do
  if type(val) == "table" then
    ngx.say("key: ", key, ", val: ", table.concat(val, ", "))
  else
    ngx.say("key: ", key, ", val: ", val)
  end
end
