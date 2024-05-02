local component = require("component")
local gpu = component.gpu
local tty = require("tty")
local shell = require("shell")
local event = require("event")
local args, ops = shell.parse(...)
local filesystem = require("filesystem")

-- $screen -> list
-- $screen 1 -> switch
-- $screen 1 --primary -> set as primary screen

if #args == 0 then
  print("Usage: screen [index] [--primary]")
  print("Available screens:")
  local i = 1
  for k,v in pairs(component.list("screen")) do
    if k == gpu.getScreen() then gpu.setForeground(0xFFFF18) else gpu.setForeground(0xffffff) end
    print(i,k)
    i=i+1
  end
elseif #args == 1 then
  local index = tonumber(args[1])
  local i = 1
  local name = ""
  for k,v in pairs(component.list("screen")) do
    if i==index then name=k end
    i=i+1
  end
  if name==""  then error("Invalid screen index") end
  tty.clear()
  component.setPrimary("screen",name)
  os.sleep(0.1)
  gpu.bind(name)
  local key = component.proxy(name).getKeyboards()[1]
  tty.clear()
  component.setPrimary("keyboard",key)
  os.sleep(0.1)
  if ops["primary"] then
    _G._SCREEN_PRIMARY=name
    if filesystem.exists("/etc/bootconfig") then
      local handle,err = io.open("/etc/bootconfig","r")
      if not handle then error(err) end
      local data = handle:read("*a")
      handle:close()
      local data = string.gsub(data,"_G%._SCREEN_PRIMARY *= *\"........-....-....-....-............\".-\n","_G._SCREEN_PRIMARY = \""..name.."\"\n")
      local handle,err = io.open("/etc/bootconfig","w")
      if not handle then error(err) end
      handle:write(data)
      handle:close()
    end
  end
end