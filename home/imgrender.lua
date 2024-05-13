
local shell = require("shell")
local util = require("util")
local comp = require("component")
local gpu = comp.gpu
local tty = require("tty")

local a = shell.resolve(...)

local fh = io.open(a,"r")
local raw = fh:read("*a")
fh:close()

local len = string.len(raw)-6
local data = string.sub(raw,0,len)
local width = tonumber(string.sub(raw,len+1,len+3))
local height = tonumber(string.sub(raw,len+4,len+6))

local img ={}
for i=1,width*height,1 do
  img[i]=tonumber("0x"..string.sub(data,i*6-5,i*6))
end

print(tostring(width).." * "..tostring(height))
tty.clear()

for i=1,width,1 do
  for j=1,height,1 do
    gpu.setBackground(img[i + width*j - width])
    gpu.set(i,j+1," ")
  end
end
while true do
  os.sleep(1)
end