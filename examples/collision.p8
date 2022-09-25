pico-8 cartridge // http://www.pico-8.com
version 37
__lua__
#include qico.lua

function _init()
  -- Set up event queue
  player = {
    pos = {48,64}, -- (x, y)
    size = {8, 8}, -- (w, h)
    color = 12, -- light blue
    name = "p1",
  }
  player.handle_collision = function(new_name)
    player.name = new_name
    player.pos = {48, 64}
  end
  player.draw = function()
    print(player.name, player.pos[1], player.pos[2] - 8, player.color)
    rectfill(player.pos[1], player.pos[2], player.pos[1] + 8, player.pos[2] + 8, player.color)
  end

  baddie = {
    pos = {112, 64}, -- (x, y)
    size = {8, 8}, -- (w, h)
    color = 8, -- red 
  }
  baddie.draw = function()
    rectfill(baddie.pos[1], baddie.pos[2], baddie.pos[1] + 8, baddie.pos[2] + 8, baddie.color)
  end
  baddie.handle_collision = function()
    baddie.color = flr(rnd(15))
  end

  q = qico()
  q.add_topics("collision")
  q.add_subs("collision", {player.handle_collision, baddie.handle_collision})
end

function _draw()
  cls(15)
  baddie.draw()
  player.draw()
end

function _update()
    if btn(2) then
      player.pos[2] -= 1
    end

    if btn(3) then
      player.pos[2] += 1
    end

    if btn(0) then
      player.pos[1] -= 1
    end

    if btn(1) then
      player.pos[1] += 1
    end

    if collides(player, baddie) then
      local names = {"bo", "ao", "ai", "jo"}
      local new_name = names[flr(rnd(#names) + 1)]
      q.add_event("collision", new_name)
    end

    q.proc()
end

function collides(s0, s1)
  if (
    s0.pos[1] < (s1.pos[1] + s1.size[1])
    and (s0.pos[1] + s0.size[1]) > s1.pos[1]
    and (s0.pos[2] + s0.size[2]) > s1.pos[2]
    and s0.pos[2] < (s1.pos[2] + s1.size[2])
    ) then
    return true
  end

  return false
end
