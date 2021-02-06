config = {
  max_speed = 10,
  acceleration = 0.1,
  max_turn = math.pi/30,
  height = function() return 100 end,
  bottom = 20,
  target_speed = 5,
  min_distance = 10,
}

local function distance(p1, p2)
  local x, y = p1.x - p2.x, p1.y - p1.y
  return math.sqrt(x * x + y * y)
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

local function make_hunter()
  return {
    x = math.random(0, screen_width),
    y = math.random(screen_height - config.height(), screen_height - config.bottom),
    speed = config.max_speed,
    wokka_counter = 0,
    update_position = function(self)
      self.x = self.x + self.speed * math.cos(self.heading)
      self.y = self.y + self.speed * math.sin(self.heading)
    end,
    draw = function(self)
      love.graphics.setColor(255,255,255,255)
      love.graphics.circle("fill", self.x, self.y, 10)
      love.graphics.setColor(0,0,0,255)
      love.graphics.polygon("fill",
        self.x, self.y,
        self.x + 20*math.cos(self.heading + 1 * math.sin(self.wokka_counter)),
        self.y + 20*math.sin(self.heading + 1 * math.sin(self.wokka_counter)),
        self.x + 20*math.cos(self.heading - 1 * math.sin(self.wokka_counter)),
        self.y + 20*math.sin(self.heading - 1 * math.sin(self.wokka_counter))
      )
      hunter.wokka_counter = hunter.wokka_counter + 0.3 * hunter.speed / config.max_speed
    end
  }
end

local function make_target()
  return {
    x = math.random(0, screen_width),
    y = screen_height,
    heading = math.random() * math.pi * 2,
    draw = function(self)
      love.graphics.setColor(255,255,255,255)
      love.graphics.line(self.x, self.y-2, self.x, self.y+2)
      love.graphics.line(self.x-2, self.y, self.x+2, self.y)
    end,
    is_out_of_bounds = function(self)
      return self.x < 0 or self.x > screen_width or self.y < 0 or self.y > screen_height
    end,
    reset = function(self)
      self.x = math.random(0, screen_width)
      self.y = screen_height
      self.heading = math.atan2(screen_height/2 - self.y, screen_width/2 - self.x)
    end,
    move = function(self)
      self.x = self.x + math.cos(self.heading) * config.target_speed
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
  
  hunter = make_hunter()
  
  hunter.heading = math.atan2(target.y - hunter.y, target.x - hunter.x)
end

function love.update(dt)
  if distance(target, hunter) < config.min_distance or target:is_out_of_bounds() then
    while distance(target, hunter) < config.min_distance do
      target:reset()
    end
  else
    target:move()
  end
  
  local angle_to_target = math.atan2(target.y - hunter.y, target.x - hunter.x)
  local angle_diff = angle_diff(hunter.heading, angle_to_target)
  
  if math.abs(angle_diff) < config.max_turn then
    hunter.heading = angle_to_target
  elseif angle_diff < 0 then
    hunter.heading = hunter.heading + config.max_turn
  else
    hunter.heading = hunter.heading - config.max_turn
  end
  
  hunter.speed = hunter.speed * (1 - 0.1 * math.min(math.abs(angle_diff), config.max_turn) / config.max_turn)
  if hunter.speed < config.max_speed then
    hunter.speed = hunter.speed + config.acceleration
  end
  
  hunter:update_position()
end

local first = true
function love.draw()
  love.graphics.setColor(255,255,255,255)
  hunter:draw()
  target:draw()
  --love.graphics.circle("line", target.x, target.y, 10, 10)
  --love.graphics.line(hunter.x, hunter.y, hunter.x+30*math.cos(hunter.heading), hunter.y+30*math.sin(hunter.heading))
  --love.graphics.line(target.x, target.y, hunter.x, hunter.y)

end

function love.keypressed(key, scancode, isrepeat)
  love.event.quit()
end
