local shell = require("shell")
local util = require("util")
local comp = require("component")
local gpu = comp.gpu
local tty = require("tty")
local fs = require("filesystem")
local event = require("event")

--filename
local file = shell.resolve(...)

--read data from original image
local org = {}
if fs.exists(file) then
  local fh = io.open(file,"r")
  org.raw = fh:read("*a")
  fh:close()
else org.raw = "000000000000" end

--get data from image
org.len = string.len(org.raw)-6
org.data = string.sub(org.raw,0,org.len)
org.width = tonumber(string.sub(org.raw,org.len+1,org.len+3))
org.height = tonumber(string.sub(org.raw,org.len+4,org.len+6))

--get 1d RGB pixel array
org.img ={}
for i=1,org.width*org.height,1 do
  org.img[i]=tonumber("0x"..string.sub(org.data,i*6-5,i*6))
end

--edited image array
local edit = {}
edit.data = ""
edit.width,edit.height = gpu.getResolution()
edit.img = {}

local tmp = {}
--tmp out of range fix
for i=1,edit.width,1 do
  tmp[i] = {}
end

--clear screen, render image and make 2D tmp array from original image
tty.clear()
for i=1,org.width,1 do
  for j=1,org.height,1 do
    local tmp1 = org.img[i+org.width*j-org.width]
    gpu.setBackground(tmp1)
    gpu.set(i,j+1," ")
    tmp[i][j] = tmp1
  end
end
------------------------------------------------------------------------------------------------------------------------
os.sleep(0.25)

--convert 2d tmp to 1d edit image
for i=0,edit.width*edit.height,1 do
  local x = math.floor(i%edit.width)+1
  local y = math.floor(i/edit.width)+1
  edit.img[i+1] = tmp[x][y]
end

--render image
for i=1,edit.width,1 do
  for j=1,edit.height,1 do
    local tmpx = tmp[i][j]
    if not tmpx then tmpx=0x000000 end
    gpu.setBackground(tmpx)
    gpu.set(i,j+1," ")
  end
end

local color = 0x000000

--render color "overlay"
local function overlay()
  gpu.setBackground(color+0x330000)
  gpu.set(10,1," ")
  gpu.setBackground(color-0x330000)
  gpu.set(11,1," ")
  gpu.setBackground(color+0x002400)
  gpu.set(13,1," ")
  gpu.setBackground(color-0x002400)
  gpu.set(14,1," ")
  gpu.setBackground(color+0x000040)
  gpu.set(16,1," ")
  gpu.setBackground(color-0x000040)
  gpu.set(17,1," ")
  gpu.setBackground(0xFFFFFF)
  gpu.set(20,1," ")
  gpu.setBackground(0x000000)
  gpu.set(21,1," ")
  gpu.setBackground(0xFF0000)
  gpu.set(22,1," ")
  gpu.setBackground(0x00FF00)
  gpu.set(23,1," ")
  gpu.setBackground(0x0000FF)
  gpu.set(24,1," ")
  gpu.setBackground(0x000000)
  gpu.set(26,1,string.format("%X",color).."        ")
  gpu.setBackground(color)
end

overlay()

--ontouch function
local function ontouch(a,b,c,d,e,f)
  if d <= 1 then 
    if c == 10 then color=color+0x330000
    elseif c == 11 then color=color-0x330000
    elseif c == 13 then color=color+0x002400
    elseif c == 14 then color=color-0x002400
    elseif c == 16 then color=color+0x000040
    elseif c == 17 then color=color-0x000040
    elseif c == 20 then color=0xFFFFFF
    elseif c == 21 then color=0x000000
    elseif c == 22 then color=0xFF0000
    elseif c == 23 then color=0x00FF00
    elseif c == 24 then color=0x0000FF
    end
    if color>0xFFFFFF or color<0x0 then color=0x777777 end
    overlay()
  else
    gpu.set(c,d," ")
    edit.img[c+edit.width*d-(edit.width*2)] = color
  end
end

--onkey function
local function onkey(a,b,c,d)
  if c==19 and d==31 then -- ctrl+s
    local out = io.open(file..".o","a")
    gpu.setBackground(0x000000)
    gpu.set(1,1,"Saving...")
    for i=1,edit.width*edit.height,1 do
      if i%1000==0 then os.sleep(0.05) end
      a=edit.img[i] or 0
      b=string.format("%X",a)
      if string.len(b)>5 then out:write(b) else
        repeat b="0"..b until string.len(b)>5
        out:write(b)
      end
    end

    local tmp = tostring(edit.width)
    if string.len(tmp)>2 then out:write(tmp) else
      repeat tmp="0"..tmp until string.len(tmp)>2
      out:write(tmp)
    end

    local tmp = tostring(edit.height)
    if string.len(tmp)>2 then out:write(tmp) else
      repeat tmp="0"..tmp until string.len(tmp)>2
      out:write(tmp)
    end
    
    gpu.setBackground(0x000000)
    gpu.set(1,1,"Saved    ")
    gpu.setBackground(color)
    out:close()
  end
end

local evid = event.listen("touch",ontouch)
local evid1 = event.listen("drag",ontouch)
local evid2 = event.listen("interrupted",function(a) run = false end)
local evid3 = event.listen("key_down",onkey)

run = true
while run do os.sleep(1) end

gpu.setBackground(0x000000)
tty.clear()
event.cancel(evid)
event.cancel(evid1)
event.cancel(evid2)
event.cancel(evid3)