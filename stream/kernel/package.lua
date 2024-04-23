local package = {}
local proxy = component.proxy
local addr = computer.getBootAddress()

local loaded = {}
local failed = {}

package.loaded = loaded
package.failed = failed
package.require = function(module,fs,env)
  checkArg(1,module,"string")--process module path

  local handle = assert(fs.open(module,"rb"))

  local buffer = ""
  repeat
    local data = fs.read(handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  fs.close(handle)

  lib, status = load(buffer, module, "bt", env)

  status, lib = pcall(lib, module)
  assert(status, tostring(lib))

  lib._CREATED = fs.lastModified(module)

  loaded[module] = lib
  return lib
end

package.search = function(name)--TODO--hledat,--TODO--require("filesystem") == proxy("filesystem")
end

function require(module)
  if loaded[module] then return loaded[module] end
  local fs = require("filesystem")
  if not loaded[module] or loaded[module]._CREATED < fs.lastModified(module) then
    package.require(module,fs,_G)
  end
  return loaded[module]
end

loaded["bit32"] = bit32
loaded["debug"] = debug
loaded["math"] = math
loaded["os"] = os
loaded["string"] = string
loaded["table"] = table
loaded["component"] = component
loaded["computer"] = computer
loaded["unicode"] = unicode
loaded["utf8"] = utf8
loaded["filesystem"] = proxy(addr)

return package