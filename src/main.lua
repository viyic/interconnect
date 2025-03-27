require('src.common')

local mode = { load = nil, update = nil, draw = nil }

local function set_mode(new_mode)
  mode = require(new_mode)
  mode.load()
end

local font = love.graphics.newFont("data/font/IBMPlexMono-Regular.ttf", 24)
local music = love.audio.newSource("data/audio/stardust-ep-track-1-exclusive-pixabay-music-196787.mp3", "static")
music:setLooping(true)

love.load = function()
  love.graphics.setFont(font)
  music:play()
  set_mode("src.menu")
end

love.update = function(dt)
  mode.update(dt, set_mode)
end

love.draw = function()
  mode.draw(set_mode)
end
