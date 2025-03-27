lume = require("lib.lume")

debug_mode = true

-- taken from: stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k, v in pairs(o) do
         if type(k) ~= 'number' then k = '"' .. k .. '"' end
         s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function db(x)
   if (debug_mode == true) then
      local debug_info = debug.getinfo(1)
      -- print debug.getinfo
      local currentline = debug_info.currentline
      -- local file = debug_info.source:match("^.+/(.+)$")
      local file = debug_info["short_src"] or ""
      local name = debug_info["namewhat"] or ""
      print("db " .. dump(x))
   end
end

require("src.main")
