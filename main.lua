config = {
  max_speed = 10,
  acceleration = 0.1,
  max_turn = math.pi/30,
  height = function() return 100 end,
  bottom = 20,
  target_speed = 3,
  min_distance = 20,
}

function distance(p1, p2)
  local x, y = p1.x - p2.x, p1.y - p1.y
  return math.sqrt(x * x + y * y)
end

function angle_diff(a, b)
  local d = math.abs(a - b) % (2*math.pi)
  local r = d > math.pi and 2*math.pi - d or d

  if (a - b >= 0 and a - b <= math.pi) or (a - b <=-math.pi and a- b>= -2*math.pi) then
    return r
  else
    return -r
  end 
end

function love.load(arg)
  if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
  shots = {}
  love.window.setFullscreen(true)
  screen_width, screen_height = love.window.getMode()
  
  target = {
    x = math.random(0, screen_width),
    y = screen_height,
    heading = math.random() * math.pi * 2;
  }
  
  hunter = {
    x = math.random(0, screen_width),
    y = math.random(screen_height - config.height(), screen_height - config.bottom),
    speed = config.max_speed,
    wokka_counter = 0,
  }
  
  hunter.heading = math.atan2(target.y - hunter.y, target.x - hunter.x)
end

function love.update(dt)
  if distance(target, hunter) < config.min_distance or target.y < 0 then
    while distance(target, hunter) < config.min_distance do
      target.x = math.random(0, screen_width)
      target.y = screen_height
      target.heading = math.atan2(screen_height/2 - target.y, screen_width/2 - target.x)
    end
  else
    target.x = target.x + math.cos(target.heading) * config.target_speed
    target.y = target.y + math.sin(target.heading) * config.target_speed * (target.y/screen_height)
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
  
  hunter.x = hunter.x + hunter.speed * math.cos(hunter.heading)
  hunter.y = hunter.y + hunter.speed * math.sin(hunter.heading)
end

local first = true
function love.draw()
  love.graphics.setColor(255,255,255,255)
  love.graphics.circle("fill", hunter.x, hunter.y, 10, 10)
  --love.graphics.circle("line", target.x, target.y, 10, 10)
  --love.graphics.line(target.x, target.y-2, target.x, target.y+2)
  --love.graphics.line(target.x-2, target.y, target.x+2, target.y)
  --love.graphics.line(hunter.x, hunter.y, hunter.x+30*math.cos(hunter.heading), hunter.y+30*math.sin(hunter.heading))
  --love.graphics.line(target.x, target.y, hunter.x, hunter.y)

  love.graphics.setColor(0,0,0,255)
  love.graphics.polygon("fill",
    hunter.x, hunter.y,
    hunter.x + 20*math.cos(hunter.heading + 1 * math.sin(hunter.wokka_counter)),
    hunter.y + 20*math.sin(hunter.heading + 1 * math.sin(hunter.wokka_counter)),
    hunter.x + 20*math.cos(hunter.heading - 1 * math.sin(hunter.wokka_counter)),
    hunter.y + 20*math.sin(hunter.heading - 1 * math.sin(hunter.wokka_counter))
  )
  hunter.wokka_counter = hunter.wokka_counter + 0.3 * hunter.speed / config.max_speed
end

function love.keypressed(key, scancode, isrepeat)
  love.event.quit()
end
