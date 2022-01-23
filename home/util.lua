local export = {}

function export.genarr(x,y,def)
  local arr = {}
  for i=1,x,1 do
    arr[i]={}
    for j=1,y,1 do
      arr[i][j]=def
    end
  end
 return arr
end

function export.print1table(it,start,ende)
  checkArg(1,it,"table")
  checkArg(2,start,"number","nil")
  checkArg(3,ende,"number","nil")
  
  start = start or 1
  ende = ende or #it
  for i=start,ende,1 do
    print(it[i])
  end
end

export.index = 0

function export.offset()
  export.index=export.index+1
  return export.index
end

function export.reset()
  local tmp = export.offset()
  export.index=0
  return tmp
end

return export