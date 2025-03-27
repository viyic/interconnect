local function point_in_rectangle_3f(x, y, x1, y1, x2, y2)
  if ((x >= x1) and (x <= x2) and (y >= y1) and (y <= y2)) then
    return true
  else
    return false
  end
end
local function draw_rectangle(mode, x, y, w, h, radius)
  return love.graphics.rectangle(mode, x, y, w, h, radius)
end
local function draw_rectangle_centered(mode, x, y, w, h, radius)
  return love.graphics.rectangle(mode, (x - (w / 2)), (y - (h / 2)), w, h, radius)
end
local function draw_text(x, y, text)
  local font = love.graphics.getFont()
  return love.graphics.print(text, x, y, 0, 1, 1, (font:getWidth(text) / 2), (font:getHeight() / 2))
end
local function draw_line(x1, y1, x2, y2, width)
  love.graphics.setLineWidth(width)
  return love.graphics.line(x1, y1, x2, y2)
end
local function rgb(r, g, b)
  return (r / 255), (g / 255), (b / 255)
end
return rgb 