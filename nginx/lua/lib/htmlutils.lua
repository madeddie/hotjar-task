local M = {}

local entities =
{
--  ['&'] = "&amp;",
  ['<'] = "&lt;",
  ['>'] = "&gt;"
}

function M.encode(msg)
  if msg == nil or type(msg) ~= "string" then
    return ''
  end

  msg = string.gsub(msg, '&', "&amp;")
  for char, entity in pairs(entities) do
    msg = string.gsub(msg, char, entity)
  end
  return msg
end

return M
