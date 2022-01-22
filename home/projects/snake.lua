local comp = require("component")
local clearscreen = require("tty").clear
local event = require("event")
local util = require("util")
local run = true
local gpu = comp.gpu
local gW,gH = gpu.getResolution()

local board = util.genarr(gW,gH,{x=0,y=0})

clearscreen()

local empty,snake,egg = '.','#','*'
local snakelen = 1
local pX,pY = 10,10
local dir = 3

local function oninput(_,_,c,d,_)
  if c==0 then 
    if d==203 then dir=0     --left
    elseif d==200 then dir=3 --up
    elseif d==205 then dir=1 --right
    elseif d==208 then dir=2 --down
    end
  end
end

local function move()
  if dir==0 then pX = pX-1         --left
    board[pX+1][pY] = {x=pX,y=pY}
  elseif dir==1 then pX = pX+1     --right
    board[pX-1][pY] = {x=pX,y=pY}
  elseif dir==2 then pY = pY+1     --down
    board[pX][pY-1] = {x=pX,y=pY}
  elseif dir==3 then pY = pY-1     --up
    board[pX][pY+1] = {x=pX,y=pY}
  end
  
  local tmp = {x=pX,y=pY}
  for i=0,snakelen,1 do if tmp.x==nil or tmp.x==0 or tmp.y==nil or tmp.y==0 then tmp={x=pX,y=pY} end tmp = {x=board[tmp.x][tmp.y].x,y=board[tmp.x][tmp.y].y} end
  board[tmp.x][tmp.y] = {x=0,y=0}
  gpu.set(tmp.x,tmp.y,empty)
end

local function render()
  gpu.set(pX,pY,snake)
end

local evid = event.listen("key_down",oninput)
local evid1 = event.listen("interrupted",function(a) run=false end)

while run do move() render() os.sleep(0.1) end

event.cancel(evid)
event.cancel(evid1)