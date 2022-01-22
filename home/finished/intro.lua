local a="\n                      /----------\\       /------------------\n                      |          |                         |\n                      |          |                         |\n                      |          |                         |\n                      |          |                         |\n                      |          |                         |\n                      |----------/                         |\n                      |                          ----------|\n                      |                                    |\n                      |                                    |\n                      |                                    |\n                      |                                    |\n                      |                                    |\n                      |                                    |\n                      |                                    |\n                      |                  \\-----------------/\n                      |\n                      |\n                      |\n                      |"

for i=0,string.len(a),10 do
  io.write(string.sub(a,i,i+9))
  os.sleep(0)
end

os.sleep(2)