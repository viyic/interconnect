local window_width = love.graphics.getWidth()
local window_height = love.graphics.getHeight()
local grid_size = 100

local camera = {x = 0, y = 0}

local mx = 0
local my = 0

local context_menu_open = false
local context_menu_x = 0
local context_menu_y = 0

local builds = {"drill", "processor", "connector"}
local build_prices = {25, 40, "10/grid"}
local building = 0
local building_x = 0
local building_y = 0
local building_from = 0
local building_to = 0
local building_entity = 0
local building_obstructed = false
local building_price = 0

local entities = {}
local connectors = {}
local effects = {}

local gen_id = 1
local drill_max_durability = 100
local drill_price = 25
local connector_price = 10
local processor_price = 40
local generator_energy = 1000
local fuel = 0
local gold = 100
local energy_time = 1
local energy_timer = 1

local small_font = love.graphics.newFont("data/font/IBMPlexMono-Regular.ttf", 14)

function create_entity(x, y, type, entity)
  local id = gen_id
  gen_id = (gen_id + 1)

  local w, h = nil, nil
  if (type == "generator") then
    w, h = 2, 2
  else
    w, h = 1, 1
  end

  local durability
  if (type == "drill") then
    durability = drill_max_durability
  else
    durability = 99999
  end

  local drill_type
  if (type == "drill") then
    drill_type = entity.type
  else
    drill_type = nil
  end

  return table.insert(entities, {id = id, x = x, y = y, w = w, h = h, type = type, ["drill-type"] = drill_type, durability = durability})
end

function get_entity_id_from_position(x, y, ix)
  local index = (ix or 1)
  local entity = entities[index]
  if (entity == nil) then
    return 0
  elseif point_in_rectangle_3f(x, y, entity.x, entity.y, (entity.x + (entity.w - 1)), (entity.y + (entity.h - 1))) then
    return entity.id
  else
    return get_entity_id_from_position(x, y, (index + 1))
  end
end

function get_entity_index_from_id(id, ix)
  local index = (ix or 1)
  local entity = entities[index]
  if (entity == nil) then
    return 0
  elseif (entity.id == id) then
    return index
  else
    return get_entity_index_from_id(id, (index + 1))
  end
end

function create_effect(x, y, type, text)
  return table.insert(effects, {x = x, y = y, type = type, text = text, timer = 1})
end

function load()
  math.randomseed(os.time())

  create_entity(4, 3, "generator")

  for index = 1, 20 do
    local function create_gold()
      local x = lume.round(lume.random(-15, 15))
      local y = lume.round(lume.random(-15, 15))
      local entity = get_entity_id_from_position(x, y)
      if (entity == 0) then
        create_entity(x, y, "gold")
      else
      end
      if (entity ~= 0) then
        return create_gold()
      else
        return nil
      end
    end
    create_gold()
  end

  for index = 1, 20 do
    local function create_fuel()
      local x = lume.round(lume.random(-15, 15))
      local y = lume.round(lume.random(-15, 15))
      local entity = get_entity_id_from_position(x, y)
      if (entity == 0) then
        create_entity(x, y, "fuel")
      else
      end
      if (entity ~= 0) then
        return create_fuel()
      else
        return nil
      end
    end
    create_fuel()
  end
end

local mouse = {
  left = {
    index = 1,
    down = false,
    pressed = false,
    released = false
  },
  right = {
      index = 2,
    down = false,
    pressed = false,
    released = false
  },
  middle = {
    index = 3,
    down = false,
    pressed = false,
    released = false
  }
}

function update_mouse()
  for key, button in pairs(mouse) do
    local down = love.mouse.isDown(button.index)
    if down then
      button.pressed = not button.down
      button.down = true
    else
    end
    if not down then
      button.released = button.down
      button.down = false
    else
    end
  end
end

function update(dt, set_mode)
  mx, my = love.mouse.getPosition()
  update_mouse()

  local cam_speed = 200

  if love.keyboard.isDown("escape") then
    entities = {}
    connectors = {}
    generator_energy = 1000
    fuel = 0
    gold = 100
    energy_time = 1
    energy_timer = 1
    set_mode("src.menu")
  end

  local margin_x = 200
  local build_w = (window_width - (margin_x * 2))
  local build_h = 100
  local build_x = margin_x
  local build_y = (window_height - build_h)
  local hover = point_in_rectangle_3f(mx, my, build_x, build_y, (build_x + build_w), (build_y + build_h))
  local scroll_area = 100
  if (love.keyboard.isDown("w") or (not hover and (my < scroll_area))) then
    camera.y = (camera.y - (dt * cam_speed))
  end

  if (love.keyboard.isDown("s") or (not hover and (my > (window_height - scroll_area)))) then
    camera.y = (camera.y + (dt * cam_speed))
  end

  if (love.keyboard.isDown("a") or (not hover and (mx < scroll_area))) then
    camera.x = (camera.x - (dt * cam_speed))
  end

  if (love.keyboard.isDown("d") or (not hover and (mx > (window_width - scroll_area)))) then
    camera.x = (camera.x + (dt * cam_speed))
  end

  camera.x = math.min(math.max(camera.x, (-22 * grid_size)), (22 * grid_size))
  camera.y = math.min(math.max(camera.y, (-22 * grid_size)), (22 * grid_size))

  if (energy_timer > 0) then
    energy_timer = (energy_timer - dt)
  end

  if (energy_timer <= 0) then
    for index, connector in ipairs(connectors) do
      if (generator_energy > 0) then
        local to = entities[get_entity_index_from_id(connector.to)]
        if (to.type == "drill") then
          if (to["drill-type"] == "gold") then
            gold = (gold + 1)
          end
          if (to["drill-type"] == "fuel") then
            fuel = (fuel + 1)
          end
        end
        if ((to.type == "processor") and (fuel >= 1)) then
          fuel = (fuel - 1)

          generator_energy = (generator_energy + 4)
        end

        generator_energy = (generator_energy - 1)
      end
    end

    energy_timer = (energy_timer + energy_time)
  end

  if (building ~= 0) then
    building_x = lume.round((((mx + camera.x) - (grid_size / 2)) / grid_size))
    building_y = lume.round((((my + camera.y) - (grid_size / 2)) / grid_size))
    building_entity = get_entity_id_from_position(building_x, building_y)
    local entity = entities[get_entity_index_from_id(building_entity)]
    local build = builds[building]
    building_obstructed = true
    if (build == "drill") then
      if ((entity ~= nil) and ((entity.type == "gold") or (entity.type == "fuel")) and (gold >= drill_price)) then
        building_obstructed = false
      end
    end

    if (build == "connector") then
      if ((entity ~= nil) and ((entity.type ~= "gold") or ("gold" ~= "fuel"))) then
        building_obstructed = false
      end

      local from = entities[get_entity_index_from_id(building_from)]
      local to = entity
      if ((from ~= nil) and (to ~= nil)) then
        local price = lume.round((lume.distance((from.x + (from.w / 2)), (to.x + (to.w / 2)), (from.y + (from.h / 2)), (to.y + (to.h / 2))) * connector_price))
        if (price ~= 0) then
          building_price = price
        end
      end
    end

    if (build == "processor") then
      if (entity == nil) then
        building_obstructed = false
      end
    end

    if mouse.left.pressed then
      if not building_obstructed then
        if (build ~= "connector") then
          create_entity(building_x, building_y, build, entity)
          if (build == "processor") then
            gold = (gold - processor_price)
          end
          if (build == "drill") then
            gold = (gold - drill_price)
            table.remove(entities, get_entity_index_from_id(building_entity))
          end
          building = 0
        end

        if (build == "connector") then
          local step = false
          if (building_from == 0) then
            if (entity.type == "generator") then
              building_from = building_entity
            end

            if (entity.type ~= "generator") then
              local function get_connector_index_from_entity_id(id, ix)
                local index = (ix or 1)
                local connector = connectors[index]
                db(id)
                db(connector)
                if (connector == nil) then
                  return 0
                elseif (connector.to == id) then
                  return index
                else
                  return get_connector_index_from_entity_id(id, (index + 1))
                end
              end
              local connector = get_connector_index_from_entity_id(entity.id)
              if (connector ~= 0) then
                building_from = building_entity
              end
            end

            step = true
          end
          if ((building_from ~= 0) and (building_to == 0) and not step) then
            local from = entities[get_entity_index_from_id(building_from)]
            local to = entity

            if ((gold >= building_price) and (from.id ~= to.id)) then
              building_to = building_entity
              gold = (gold - building_price)
              table.insert(connectors, {from = building_from, to = building_to})
            end

            building = 0
            building_from = 0
            building_to = 0
          end
        end
      end

      if building_obstructed then
        building = 0
        building_from = 0
        building_to = 0
      end
    end
  end

  if (love.keyboard.isDown("c") or love.keyboard.isDown("space")) then
    camera.x = 0
    camera.y = 0
  end
end

function draw(set_mode)
  love.graphics.clear(1, 1, 1)

  love.graphics.push()
  love.graphics.translate(( - camera.x), ( - camera.y))

  local x = ((lume.round((camera.x / grid_size)) - 1) * grid_size)
  local y = ((lume.round((camera.y / grid_size)) - 1) * grid_size)
  for index = 1, 10 do
    love.graphics.setColor((157 / 255), (236 / 255), (235 / 255))
    for inner_index = 0, 35 do
      draw_line((x + (index * grid_size)), (y + (inner_index * 25)), (x + (index * grid_size)), ((y + (inner_index * 25)) + 12.5), 3)
    end
    for inner_index = 0, 45 do
      draw_line((x + (inner_index * 25)), (y + (index * grid_size)), ((x + (inner_index * 25)) + 12.5), (y + (index * grid_size)), 3)
    end
  end

  local previous_font = love.graphics.getFont()
  love.graphics.setFont(small_font)
  for index, entity in ipairs(entities) do
    local x0 = (entity.x * grid_size)
    local y0 = (entity.y * grid_size)
    local w = (entity.w * grid_size)
    local h = (entity.h * grid_size)
    local text_x = (x0 + (w / 2))
    local text_y = (y0 + (h / 2))

    if (entity.type == "generator") then
      love.graphics.setColor(1, 0, 0.6)
      draw_rectangle("fill", x0, y0, w, h, 5)
      love.graphics.setColor(1, 1, 1)
      draw_text(text_x, text_y, entity.type)
      draw_text(text_x, (text_y + 24), generator_energy)
    end

    if (entity.type == "drill") then
      love.graphics.setColor(0, 0.6, 1)
      draw_rectangle("fill", x0, y0, w, h, 5)
      love.graphics.setColor(1, 1, 1)
      draw_text(text_x, text_y, entity.type)
    end

    if (entity.type == "processor") then
      love.graphics.setColor(rgb(51, 204, 47))
      draw_rectangle("fill", x0, y0, w, h, 5)
      love.graphics.setColor(1, 1, 1)
      draw_text(text_x, text_y, entity.type)
    end

    if (entity.type == "gold") then
      love.graphics.setColor(rgb(228, 196, 21))
      draw_rectangle("fill", x0, y0, w, h, 5)
    end

    if (entity.type == "fuel") then
      love.graphics.setColor(rgb(90, 70, 58))
      draw_rectangle("fill", x0, y0, w, h, 5)
    end
  end

  for index, connector in ipairs(connectors) do
    local from = entities[get_entity_index_from_id(connector.from)]
    local to = entities[get_entity_index_from_id(connector.to)]
    local from_x = ((from.x + (from.w / 2)) * grid_size)
    local from_y = ((from.y + (from.h / 2)) * grid_size)
    local to_x = ((to.x + (to.w / 2)) * grid_size)
    local to_y = ((to.y + (to.h / 2)) * grid_size)
    love.graphics.setColor(1, 0, 0.2)
    love.graphics.circle("fill", from_x, from_y, 10)
    draw_line(from_x, from_y, to_x, to_y, 5)
    love.graphics.circle("fill", to_x, to_y, 10)
  end

  if (building ~= 0) then
    local entity = entities[get_entity_index_from_id(building_entity)]
    local x0 = (building_x * grid_size)
    local y0 = (building_y * grid_size)
    local build = builds[building]
    if (build == "drill") then
      if not building_obstructed then
        love.graphics.setColor(0, 0.6, 1)
      else
        love.graphics.setColor(1, 0, 0.2)
      end
      draw_rectangle("fill", x0, y0, grid_size, grid_size, 5)
      love.graphics.setColor(1, 1, 1)
      draw_text((x0 + (grid_size / 2)), (y0 + (grid_size / 2)), build)
    end

    if (build == "processor") then
      if not building_obstructed then
        love.graphics.setColor(rgb(51, 204, 47))
      else
        love.graphics.setColor(1, 0, 0.2)
      end
      draw_rectangle("fill", x0, y0, grid_size, grid_size, 5)
      love.graphics.setColor(1, 1, 1)
      draw_text((x0 + (grid_size / 2)), (y0 + (grid_size / 2)), build)
    end

    if (build == "connector") then
      if (building_from == 0) then
        local x1
        local grid_x1
        if entity then
          grid_x1 = (entity.x + ((entity.w - 1) / 2))
        else
          grid_x1 = building_x
        end
        x1 = (grid_x1 * grid_size)
        local y1
        local grid_y1
        if entity then
          grid_y1 = (entity.y + ((entity.h - 1) / 2))
        else
          grid_y1 = building_y
        end
        y1 = (grid_y1 * grid_size)
        love.graphics.setColor(1, 0, 0.2)
        love.graphics.circle("fill", (x1 + (grid_size / 2)), (y1 + (grid_size / 2)), 10)
      end

      if (building_from ~= 0) then
        local x1 = (building_x * grid_size)
        local y1 = (building_y * grid_size)
        local from = entities[get_entity_index_from_id(building_from)]
        local from_x = ((from.x + (from.w / 2)) * grid_size)
        local from_y = ((from.y + (from.h / 2)) * grid_size)
        love.graphics.setColor(1, 0, 0.2)
        love.graphics.circle("fill", (x1 + (grid_size / 2)), (y1 + (grid_size / 2)), 10)
        love.graphics.circle("fill", from_x, from_y, 10)
        draw_line(from_x, from_y, ((building_x + 0.5) * grid_size), ((building_y + 0.5) * grid_size), 5)
      end
    end
  end

  love.graphics.pop()

  local margin_x = 200
  local w = (window_width - (margin_x * 2))
  local h = 100

  love.graphics.setColor(1, 1, 1)
  draw_rectangle("fill", margin_x, (window_height - h), w, h, 5)
  love.graphics.setColor(rgb(71, 222, 220))
  draw_rectangle("line", margin_x, (window_height - h), w, h, 5)

  for index, build in ipairs(builds) do
    local build_w = (w / #builds)
    local build_h = h
    local build_x = (margin_x + ((index - 1) * build_w))
    local build_y = (window_height - build_h)
    local hover = point_in_rectangle_3f(mx, my, build_x, build_y, (build_x + build_w), (build_y + build_h))
    if (hover or (building == index)) then
      love.graphics.setColor(0, 0.6, 1)
    else
      love.graphics.setColor(1, 1, 1)
    end
    draw_rectangle("fill", build_x, build_y, build_w, build_h, 5)
    if (hover or (building == index)) then
      love.graphics.setColor(1, 1, 1)
    else
      love.graphics.setColor(0, 0, 0)
    end
    draw_text((build_x + (build_w / 2)), (build_y + (build_h / 2)), build)
    draw_text((build_x + (build_w / 2)), ((build_y + (build_h / 2)) + small_font:getHeight()), ("gold " .. build_prices[index]))
    if (hover and mouse.left.pressed) then
      building = index
    end
  end

  love.graphics.setFont(previous_font)
  love.graphics.setColor(rgb(228, 196, 21))
  love.graphics.print(("gold " .. gold), 20, 20)
  love.graphics.setColor(rgb(90, 70, 58))
  love.graphics.print(("fuel " .. fuel), 20, (20 + 26))
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle("fill", mx, my, 4)

  if (generator_energy <= 0) then
    return set_mode("menu")
  end
end

return {load = load, update = update, draw = draw} 