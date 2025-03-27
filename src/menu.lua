local grid_size = 100
local window_width = love.graphics.getWidth()
local window_height = love.graphics.getHeight()
local mx = 0
local my = 0
local selected = 1
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
local function update(dt, set_mode)
  mx, my = love.mouse.getPosition()
  return nil
end
local function draw(set_mode)
  love.graphics.clear(1, 1, 1)
  love.graphics.setColor(0, 0, 0)
  draw_text((window_width / 2), 50, "interconnect")
  local menus = {"play", "quit"}
  local x = 0
  local y = 0
  for index = 1, 10 do
    love.graphics.setColor((157 / 255), (236 / 255), (235 / 255))
    for inner_index = 0, 35 do
      draw_line((x + (index * grid_size)), (y + (inner_index * 25)), (x + (index * grid_size)), ((y + (inner_index * 25)) + 12.5), 3)
    end
    for inner_index = 0, 45 do
      draw_line((x + (inner_index * 25)), (y + (index * grid_size)), ((x + (inner_index * 25)) + 12.5), (y + (index * grid_size)), 3)
    end
  end
  local margin_x = 300
  local w = (window_width - (margin_x * 2))
  local h = (window_height - (margin_x * 2))
  love.graphics.setColor(rgb(71, 222, 220))
  draw_rectangle("fill", (margin_x - 20), (margin_x - 20), (w + 40), (h + 40), 5)
  for index, menu in ipairs(menus) do
    local build_w = w
    local build_h = (h / #menus)
    local build_x = margin_x
    local build_y = (margin_x + ((index - 1) * build_h))
    local hover = point_in_rectangle_3f(mx, my, build_x, build_y, (build_x + build_w), (build_y + build_h))
    if hover then
      love.graphics.setColor(0, 0.6, 1)
    else
      love.graphics.setColor(1, 1, 1)
    end
    draw_rectangle("fill", build_x, build_y, build_w, build_h, 5)
    if hover then
      love.graphics.setColor(1, 1, 1)
    else
      love.graphics.setColor(0, 0, 0)
    end
    draw_text((build_x + (build_w / 2)), (build_y + (build_h / 2)), menu)
    if (hover and love.mouse.isDown(1)) then
      if (index == 1) then
        set_mode("src.game")
      else
      end
      if (index == 2) then
        love.event.quit()
      else
      end
    else
    end
  end
  return nil
end
local function load()
  return true
end
return {load = load, update = update, draw = draw} 