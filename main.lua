config = {
  max_speed = 10,
  acceleration = 0.2,
  max_turn = math.pi/30,
  height = function() return 100 end,
  bottom = 20,
  target_speed = 1,
  min_distance = 10,
  margin_x = 0.1, -- left and right margin as a proportion of the screen
  draw_target = true,
  max_attract_speed = 20,
  growth_rate = 2,
  shrink_rate = 0.99,
  debug = false,
}

local function length(vector)
  return math.sqrt(vector.x * vector.x + vector.y * vector.y)
end

local function distance(p1, p2)
  local v = {}
  v.x, v.y = p1.x - p2.x, p1.y - p1.y
  return length({ x = p1.x - p2.x, y = p1.y - p1.y })
end

local function normalize(vector)
  local l = length(vector)
  return { x = vector.x / l, y = vector.y / l }
end

local function angle_diff(a, b)
  local d = math.abs(a - b) % (2*math.pi)
  local r = d > math.pi and 2*math.pi - d or d

  if (a - b >= 0 and a - b <= math.pi) or (a - b <=-math.pi and a- b>= -2*math.pi) then
    return r
  else
    return -r
  end 
end

local function make_hunter(initial_size)
  local size = initial_size
  return {
    x = math.random(0, screen_width),
    y = math.random(screen_height - config.height(), screen_height - config.bottom),
    speed = config.max_speed,
    wokka_counter = 0,
    move_towards = function(self, target)
      local angle_to_target = math.atan2(target.y - self.y, target.x - self.x)
      local angle_diff = angle_diff(self.heading, angle_to_target)
      
      if math.abs(angle_diff) < config.max_turn then
        self.heading = angle_to_target
      elseif angle_diff < 0 then
        self.heading = self.heading + config.max_turn
      else
        self.heading = self.heading - config.max_turn
      end
      
      self.speed = self.speed * (1 - 0.1 * math.min(math.abs(angle_diff), config.max_turn) / config.max_turn)
      if self.speed < config.max_speed then
        self.speed = self.speed + config.acceleration
      end
      
      self.x = self.x + self.speed * math.cos(self.heading)
      self.y = self.y + self.speed * math.sin(self.heading)
    end,
    draw = function(self)
      local size2 = 2 * size
      love.graphics.setColor(255,255,255,255)
      love.graphics.circle("fill", self.x, self.y, size)
      love.graphics.setColor(0,0,0,255)
      love.graphics.polygon("fill",
        self.x, self.y,
        self.x + size2*math.cos(self.heading + 1 * math.sin(self.wokka_counter)),
        self.y + size2*math.sin(self.heading + 1 * math.sin(self.wokka_counter)),
        self.x + size2*math.cos(self.heading - 1 * math.sin(self.wokka_counter)),
        self.y + size2*math.sin(self.heading - 1 * math.sin(self.wokka_counter))
      )
      hunter.wokka_counter = hunter.wokka_counter + 0.3 * hunter.speed / config.max_speed
    end,
    move_cursor = function(self)
      love.mouse.setPosition(hunter.x, hunter.y)
    end,
    attract_cursor = function(self)
      local cursor = {}
      cursor.x, cursor.y = love.mouse.getPosition()
      local vector_to_hunter = { x = hunter.x - cursor.x, y = hunter.y - cursor.y }
      local distance_to_hunter = length(vector_to_hunter)
      local speed = math.min(distance_to_hunter/10, config.max_attract_speed)
      local norm_vector = normalize(vector_to_hunter)
      cursor.x, cursor.y = cursor.x + norm_vector.x * speed, cursor.y + norm_vector.y * speed
      love.mouse.setPosition(cursor.x, cursor.y)
    end,
    eats = function(self, target)
      if distance(target, self) < size * 1.5 then
        size = math.min(initial_size * 3, size * config.growth_rate)
        return true
      else
        size = math.max(initial_size / 2, size * config.shrink_rate)
      end
    end
  }
end

local function make_target()
  return {
    x = math.random(config.margin_x * screen_width, (1 - config.margin_x) * screen_width),
    y = screen_height,
    dx = (math.random() - 0.5) * config.target_speed,
    heading = -math.pi/2,
    draw = function(self)
      if not config.draw_target then return end
      love.graphics.setColor(255,255,255,255)
      love.graphics.line(self.x, self.y-2, self.x, self.y+2)
      love.graphics.line(self.x-2, self.y, self.x+2, self.y)
    end,
    is_out_of_bounds = function(self)
      return self.x < 0 or self.x > screen_width or self.y < 0 or self.y > screen_height
    end,
    reset = function(self)
      self.x = math.random(config.margin_x * screen_width, (1 - config.margin_x) * screen_width)
      self.y = screen_height
      self.heading = -math.pi/2
      self.dx = (math.random() - 0.5) * config.target_speed
    end,
    move = function(self)
      self.x = self.x + math.cos(self.heading) * config.target_speed + self.dx
      self.y = self.y + math.sin(self.heading) * config.target_speed * (self.y/screen_height)
    end
  }
end

function love.load(arg)
  if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
  shots = {}
  love.window.setFullscreen(true)
  screen_width, screen_height = love.window.getMode()
  
  target = make_target()
  
  hunter = make_hunter(10)
  
  hunter.heading = math.atan2(target.y - hunter.y, target.x - hunter.x)
end

function love.update(dt)
  if hunter:eats(target) or target:is_out_of_bounds() then
    while hunter:eats(target) do
      target:reset()
    end
  else
    target:move()
  end
  
  hunter:move_towards(target)
end

function love.draw()
  love.graphics.setColor(255,255,255,255)
  hunter:draw()
  target:draw()
  if config.debug then
    love.graphics.setColor(128,128,128,255)
    love.graphics.line(hunter.x, hunter.y, hunter.x+30*math.cos(hunter.heading), hunter.y+30*math.sin(hunter.heading))
    love.graphics.line(target.x, target.y, hunter.x, hunter.y)
    local cursor_x, cursor_y = love.mouse.getPosition()
    love.graphics.line(hunter.x, hunter.y, cursor_x, cursor_y)
  end
end

function love.keypressed(key, scancode, isrepeat)
  love.event.quit()
end
