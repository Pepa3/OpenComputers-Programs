local loadf = ...
local uptime = computer.uptime

local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()--TODO:if gpu then gui/terminal else microcontroller?
if gpu then gpu = component.proxy(gpu) if not gpu.getScreen() then gpu.bind(screen) end end

local w, h = gpu.maxResolution()
gpu.setResolution(w, h)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")

local y = 1
local function pprint(msg)--primitive print
  if gpu then
    gpu.set(1, y, tostring(msg))
    if y == h then
      gpu.copy(1, 2, w, h - 1, 0, -1)
      gpu.fill(1, h, w, 1, " ")
    else
      y = y + 1
    end
  end
  os.sleep(0)
end

pprint("Loading kernel files")

local function ploadfile(file,...)
  checkArg(1,file,"string")
  pprint("> " .. file)
  local program, reason = loadf(file)
  if program then
    local result = table.pack(pcall(program,...))
    if result[1] then
      return table.unpack(result, 2, #result)
    else
      error(result[2])
    end
  else
    error(reason)
  end
end
_G.pprint = pprint
local package = ploadfile("kernel/package.lua")
_G.package = package
local tmp = require("kernel/example.lua")
pprint(tmp.f("hello from loaded library function"))

local tmp2 = require("kernel/example.lua")
pprint(tmp2.f("this is probably function in table in RAM memory"))