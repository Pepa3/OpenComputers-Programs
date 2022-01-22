local event = require("event")
local component = require("component")
local gpu = component.gpu

local function genarr(x,y,def)
  local arr = {}
  for i=1,x,1 do
    arr[i]={}
    for j=1,y,1 do
      arr[i][j]=def
    end
  end
 return arr
end

local function rendermap(oX,oY,regX,regY,regW,regH)
	gpu.setBackground(0x000000)
	for i=1+regY,regY+regH,1 do
		for j=1+regX,regX+regW,1 do
			if map[j][i]==0 then gpu.setBackground(0x000000) gpu.set(j+oX,i+oY," ") end
			if map[j][i]==1 then gpu.setBackground(0xFFFFFF) gpu.set(j+oX,i+oY," ") end
		end
	end
end

local function touch(name,id,x,y,button)
	map[x][y]=button
	rendermap(0,0,x-1,y-1,1,1)
end

local w,h = 120,50

require("tty").clear()

gpu.fill(0,0,w,h," ")

map = map or genarr(w,h,0)

local elid = event.listen("touch",touch)
local elid2 = event.listen("drag",touch)

rendermap(0,0,0,0,w,h)

local function dist(a,b,c,d)
	checkArg(1,a,"table","number")
	checkArg(2,b,"table","number")
	checkArg(3,c,"number","nil")
	checkArg(4,d,"number","nil")
	if c then--x1,y1,x2,y2
		return math.sqrt(math.pow(c - a, 2) + math.pow(d - b, 2))
	else--node1,node2
		return math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2))
	end
end
local function heur(s,g) return dist(s,g) end

local function lowest_f(set,f)
	local lowest, bestN = math.huge,nil
	for i=1,w,1 do
		for j=1,h,1 do
		  local score = f[i][j]
		  if set[i][j] and score < lowest then lowest, bestN = score, {x=i,y=j} end
	  end
	end
	return bestN
end

function getNeighbors(nodes, n)
	local neighbors = {}
	local x,y = n.x,n.y
	if x<w and map[x+1][y] == 0 then table.insert(neighbors,{x=x+1,y=y}) end
	if x>1 and map[x-1][y] == 0 then table.insert(neighbors,{x=x-1,y=y}) end
	if y<h and map[x][y+1] == 0 then table.insert(neighbors,{x=x,y=y+1}) end
	if y>1 and map[x][y-1] == 0 then table.insert(neighbors,{x=x,y=y-1}) end
	return neighbors
end

local function not_in(set, theNode)
	for _, node in ipairs(set) do
		if node == theNode then return false end
	end
	return true
end

local run = true
local start = {x=10,y=10}
local goal = {x=80,y=35}
local came_from = {}
open = genarr(w,h,false)
open[start.x][start.y] = true
g_score = genarr(w,h,math.huge)
f_score = genarr(w,h,math.huge)
g_score[start.x][start.y] = 0
f_score[start.x][start.y] = g_score[start.x][start.y]+heur(start,goal)

closed = genarr(w,h,false)

local times = 0

local path = genarr(w,h,{x=start.x,y=start.y})

while run do

	times = times+1
  local tmp = event.pull(0,"interrupted")
  if tmp then run = false print(" "..tostring(times).." ") break end
  local cur = lowest_f(open,f_score)
  if cur.x == goal.x and cur.y == goal.y then run = false break end

  open[cur.x][cur.y]=false

  closed[cur.x][cur.y] = true

	local neighbor = {x=cur.x+1,y=cur.y}
	if neighbor.x < w then
	  t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
	  if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="-"}
	    if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
	    	g_score[neighbor.x][neighbor.y] = t_g_score
	     	f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
	    	--bad if
	    	open[neighbor.x][neighbor.y] = true
	    end
    end
  end

	local neighbor = {x=cur.x-1,y=cur.y}
	if neighbor.x > 1 then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="-"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end

	local neighbor = {x=cur.x,y=cur.y+1}
	if neighbor.y < h then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="|"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end

	local neighbor = {x=cur.x,y=cur.y-1}
	if neighbor.y > 1 then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="|"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end
--[[
	local neighbor = {x=cur.x+1,y=cur.y+1}
	if neighbor.y < h and neighbor.x < w then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="\\"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end
	local neighbor = {x=cur.x-1,y=cur.y+1}
	if neighbor.y < h and neighbor.x > 1 then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="/"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end
	local neighbor = {x=cur.x+1,y=cur.y-1}
	if neighbor.y > 1 and neighbor.x < w then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="/"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end
	local neighbor = {x=cur.x-1,y=cur.y-1}
	if neighbor.y > 1 and neighbor.x > 1 then
		t_g_score = g_score[cur.x][cur.y]+dist(cur,neighbor)
		if closed[neighbor.x][neighbor.y] == false and map[neighbor.x][neighbor.y] == 0 then
    path[neighbor.x][neighbor.y] = {x=cur.x,y=cur.y,d="\\"}
			if open[neighbor.x][neighbor.y] == false or t_g_score < g_score[neighbor.x][neighbor.y] then
				g_score[neighbor.x][neighbor.y] = t_g_score
				f_score[neighbor.x][neighbor.y] = g_score[neighbor.x][neighbor.y] + heur(neighbor,goal)
				--bad if
				open[neighbor.x][neighbor.y] = true
			end
		end
	end]]--

	if times%100==0 then
		gpu.setBackground(0x00BB00)
		for i=1,w,1 do
			for j=1,h,1 do
				if open[i][j] then gpu.set(i,j,tostring(map[i][j])) end
		  end
		end
		gpu.setBackground(0x000000)
		for i=1,w,1 do
			for j=1,h,1 do
				if not open[i][j] then rendermap(0,0,i-1,j-1,1,1) end
		  end
		end
		gpu.setBackground(0x000000)
		gpu.set(start.x,start.y,"S")
		gpu.setBackground(0x000000)
		gpu.set(goal.x,goal.y,"G")
	end
end
local cur = goal
gpu.setBackground(0x000000)
rendermap(0,0,0,0,w,h)
repeat
	os.sleep(0.1)
  gpu.set(cur.x,cur.y,path[cur.x][cur.y].d)
  cur = path[cur.x][cur.y]
until cur.x==start.x and cur.y==start.y

event.cancel(elid)
event.cancel(elid2)