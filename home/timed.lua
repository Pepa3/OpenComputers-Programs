local shell = require("shell")
local filesystem = require("filesystem")
local event = require("event")
local args, ops = shell.parse(...)
local t = require("thread")

-- for list of files in $folder, do $command $folder/$file and after $time seconds, terminate and do another $file

-- Q = quit

if #args ~= 3 then error("Not enough arguments\nUSAGE: timed.lua $command $folder $time") end

local cmd, folder, time = args[1], args[2], args[3]

folder = shell.resolve(folder)
time = tonumber(time)
if not time then error("$time is not a number") end

if not filesystem.exists(folder) then error("Folder '"..folder.."' does not exist") end

local list, err = filesystem.list(folder)
if err then error(err) end

function run(command)
	local th1 = t.create(function()
		os.execute(command)
		while true do os.sleep(1) end
	end)
	local _,_,code = event.pull(time,"key_down")
	th1:kill()
	if code == 113 then return true end --Q
end

local files = {}

local i = 1

for file in list do
	files[i] = cmd.." "..folder.."/"..file
	i=i+1
end

local exit = false

while not exit do
	for k,v in pairs(files) do
		if run(v) then exit=true break end
	end
end

require("tty").clear()
os.exit(0)