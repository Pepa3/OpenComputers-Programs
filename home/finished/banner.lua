local shell = require("shell")
local term = require("term")
local component = require("component")
local event = require("event")
local io = require("io")
local gpu = term.gpu()

if _ENV.screen then gpu.bind(_ENV.screen) end

if not utf8 or not utf8.offset then error("Requires Lua > 5.3") end

utf8.sub = function(s,i,j)
    i=utf8.offset(s,i) 
    j=(utf8.offset(s,j+1) or 0)-1    --why or 0
    return string.sub(s,i,j)
end

term.clear()

local function exit()
 gpu.setResolution(gpu.maxResolution())
 os.exit()
end

local t = {...}
local text = ""
local arr = {}

for i=1,#t do text=text..t[i].." " end

local j = 0
local k = 0
for i=1,utf8.len(text) do
  if utf8.sub(text,i,i+1)=='/n' then
    arr[j]=utf8.sub(text,k,i-1)
    j=j+1 k=i+2
  end
end
arr[j]=utf8.sub(text,k,utf8.len(text)-1)

local resX, resY = gpu.getResolution()

for i=0,j do
  if utf8.len(arr[i])>resX then print("Text je moc dlouhý, možná ho můžes rozdělit na dva řádky") exit() end
end

resX,resY = 0,j+3 --((j+1 >=3)and j+1) or 3

for i=0,j do
  if utf8.len(arr[i])>=resX then resX=utf8.len(arr[i])+2 end
end

gpu.setResolution(resX,resY)

local hresX,hresY = math.floor((resX+1)/2),resY/2

for i=0,j do
  gpu.set(hresX-utf8.len(arr[i])/2+1,hresY-(j/2)+i+1,arr[i])
end

--_,_,_,_,_=event.pull("key_down")
--exit()