local shell = require("shell")
local util = require("util")
local offset = util.offset
local reset = util.reset
local printt = util.print1table

local a,b = ...
local name = shell.resolve(a)

local dump = false
if b=="dump" then dump = true end
local dumpfile = nil

tmp = io.open(name,"r")
local program = tmp:read("*a")
tmp:close()

program = string.gsub(program,"\n"," ")

local function split(data)
  checkArg(1,data,"string")
  local parsed,i = {},1
  for token in string.gmatch(data, "([^ ]+)%s*") do
    parsed[i] = token
    i=i+1
  end
  return parsed
end

local splitdata = split(program)
if dump then
  dumpfile = io.open("dump","w")
  dumpfile:write("START\n")
  --printt(splitdata)
end

------------OPERATIONS-------------------------
local OP_INT =    offset()
local OP_PRINT =  offset()
local OP_ADD =    offset()
local OP_SUB =    offset()
local OP_STRING = offset()
local OP_MUL =    offset()
local OP_DIV =    offset()
local OP_BOOL =   offset()
local OP_LABEL =  offset()
local OP_GOTO =   offset()
local OP_SLEEP =  offset()
local OP_FUNC =   offset()
local OP_RETURN = offset()
local OP_CALL =   offset()
local OP_END =    offset()
local OP_DROP =   offset()
local OP_DUP =    offset()
local OP_EQ =     offset()
local OP_IFGOTO = offset()
reset()
local function OP_tostring(op)
  if op==OP_INT then return "OP_INT"
  elseif op==OP_PRINT then return "OP_PRINT"
  elseif op==OP_ADD then return "OP_ADD"
  elseif op==OP_SUB then return "OP_SUB"
  elseif op==OP_STRING then return "OP_STRING"
  elseif op==OP_MUL then return "OP_MUL"
  elseif op==OP_DIV then return "OP_DIV"
  elseif op==OP_BOOL then return "OP_BOOL"
  elseif op==OP_LABEL then return "OP_LABEL"
  elseif op==OP_GOTO then return "OP_GOTO"
  elseif op==OP_SLEEP then return "OP_SLEEP"
  elseif op==OP_FUNC then return "OP_FUNC"
  elseif op==OP_RETURN then return "OP_RETURN"
  elseif op==OP_CALL then return "OP_CALL"
  elseif op==OP_END then return "OP_END"
  elseif op==OP_DROP then return "OP_DROP"
  elseif op==OP_DUP then return "OP_DUP"
  elseif op==OP_EQ then return "OP_EQ"
  elseif op==OP_IFGOTO then return "OP_IFGOTO"
  else return "OP_tostring_ERR "..tostring(op) end
end
------------OPERATIONS-------------------------

local function parse(data)
  local out = {}

  for i=1,#data,1 do
    local token = data[i]
    local l = string.len(token)
    local s = string.sub(token,1,1)
    local e = string.sub(token,l,l)
    
    out[i] = {}
    
    if tonumber(token) then out[i].op = OP_INT out[i].data = tonumber(token)
    elseif s=="\"" and e=="\"" then out[i].op = OP_STRING out[i].data = string.sub(token,2,l-1)
    elseif s==":" and e==":" then out[i].op = OP_LABEL out[i].data = string.sub(token,2,l-1)
    elseif token =="+" then out[i].op = OP_ADD
    elseif token =="/" then out[i].op = OP_DIV
    elseif token =="*" then out[i].op = OP_MUL
    elseif token == "-" then out[i].op = OP_SUB
    elseif token == "print" then out[i].op = OP_PRINT
    elseif string.sub(token,0,5) == "goto:" then out[i].op = OP_GOTO out[i].data = string.sub(token,6,string.len(token))
    elseif string.sub(token,0,7) == "ifgoto:" then out[i].op = OP_IFGOTO out[i].data = string.sub(token,8,string.len(token))
    elseif token == "false" then out[i].op = OP_BOOL out[i].data = false
    elseif token == "true" then out[i].op = OP_BOOL  out[i].data = true
    elseif token == "==" then out[i].op = OP_EQ
    elseif token == "function" then out[i].op = OP_FUNC out[i].data = offset()
    elseif token == "call" then out[i].op = OP_CALL
    elseif token == "return" then out[i].op = OP_RETURN
    elseif token == "end" then out[i].op = OP_END
    elseif token == "sleep" then out[i].op = OP_SLEEP
    elseif token == "drop" then out[i].op = OP_DROP
    elseif token == "dup" then out[i].op = OP_DUP
    else out[i].op = "UNKNOWN" out[i].data = token
    end
  end
  reset()
  return out
end

local parsed = parse(splitdata)
if dump then
  dumpfile:write("PARSED\n")
  for i=1,#parsed,1 do
    dumpfile:write(OP_tostring(parsed[i].op).." "..tostring(parsed[i].data).."\n")
  end
end

local function gen_program(ops)
  local code = "--Generated by compiler\nlocal _s,_sp = {},1\nlocal function _spp() _sp=_sp+1 end\nlocal function _spd() _s[_sp] = \"--\" _sp=_sp-1 end\nlocal function call(f) return _G[f]() end\n--CODE--\n"
  
  for i=1,#ops,1 do
    local op = ops[i].op
    local data = ops[i].data
    if op == OP_INT then code=code.."_s[_sp]="..tostring(data).." _spp()\n"
    elseif op == OP_STRING then code=code.."_s[_sp]=\""..tostring(data).."\" _spp()\n"
    elseif op == OP_LABEL then code=code.."::"..tostring(data).."::\n"
    elseif op == OP_GOTO then code=code.."goto "..tostring(data).." \n"
    elseif op == OP_IFGOTO then code=code.."_spd() if _s[_sp] then goto "..tostring(data).." end\n"
    elseif op == OP_PRINT then code=code.."print(_s[_sp-1]) _spd()\n"
    elseif op == OP_SLEEP then code=code.."os.sleep(_s[_sp-1]) _spd()\n"
    elseif op == OP_DROP then code=code.."_spd()\n"
    elseif op == OP_DUP then code=code.."_s[_sp]=_s[_sp-1] _spp()\n"
    elseif op == OP_ADD then code=code.."_s[_sp-2]=_s[_sp-2]+_s[_sp-1] _spd()\n"
    elseif op == OP_SUB then code=code.."_s[_sp-2]=_s[_sp-2]-_s[_sp-1] _spd()\n"
    elseif op == OP_MUL then code=code.."_s[_sp-2]=_s[_sp-2]*_s[_sp-1] _spd()\n"
    elseif op == OP_DIV then code=code.."_s[_sp-2]=_s[_sp-2]/_s[_sp-1] _spd()\n"
    elseif op == OP_EQ  then code=code.."_s[_sp-2]=_s[_sp-2]==_s[_sp-1] _spd()\n"
    elseif op == OP_BOOL then code=code.."_s[_sp]="..tostring(data).." _spp()\n"
    elseif op == OP_FUNC then code=code.."_G.f_"..tostring(data).." = function() \n"
    elseif op == OP_RETURN then code=code.."_spd() return _s[_sp]\n"
    elseif op == OP_END then code=code.."end\n"
    elseif op == OP_CALL then code=code.."_s[_sp-1] = call(\"f_\"..tostring(_s[_sp-1]))\n"
    else code=code.."--"..tostring(op).."  "..tostring(data).."\n"
    end
  end
  reset()
  return code
end

local code = gen_program(parsed)

name=name..".o"

local out = io.open(name,"w")
out:write(code)
out:close()

if dump then
  dumpfile:write("END\n")
  dumpfile:close()
end

print("Executing "..name)
os.execute(name)