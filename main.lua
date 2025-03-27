-- fennel = require("lib.fennel").install()
lume = require("lib.lume")

debug_mode = true
-- pp = function(x) print(fennel.view(x)) end
pp = function(x) print(x) end
db = function(x)
   if (debug_mode == true) then
      local debug_info = debug.getinfo(1)
      -- print debug.getinfo
      local currentline = debug_info.currentline
      -- local file = debug_info.source:match("^.+/(.+)$")
      local file = debug_info["short_src"] or ""
      local name = debug_info["namewhat"] or ""
      pp({"db", x})
   end
end



-- fennel.path = love.filesystem.getSource() .. "/?.fnl;" ..
--    love.filesystem.getSource() .. "/src/?.fnl;" ..
--    -- love.filesystem.getSource() .. "/src/?/init.fnl;" ..
--    fennel.path

-- debug.traceback = fennel.traceback
-- table.insert(package.loaders, function(module_name)
--    local path = module_name:gsub("%.", "/") .. ".fnl"
--    if love.filesystem.getInfo(path) then
--       return function(...)
--          return fennel.eval(love.filesystem.read(path), {env=_G, filename=path}, ...), path
--       end
--    end
-- end)

require("src.main")