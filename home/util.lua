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

return export