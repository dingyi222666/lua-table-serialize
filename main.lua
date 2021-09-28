pcall(function() require "import" end) 
--require module and use global 
require "table_serialize" (true) 

local main_dir=debug.getinfo(function()end).short_src

main_dir = main_dir:match("(.+)/main.lua")

local test_path = main_dir.."/test.ltb"

do
   ByteStream(test_path,"w")
  :writeInt(1243)
  :close()
end

do
  local stream=
  ByteStream(test_path,"r") --

  print(stream:readInt())

  stream:close()
end


do

  

  local t = {
    test=13,
    aaa="6767",
    [676]=4646,
    t = {},
    a = "t",
    test=String(),
    cc=function ()
    end,
    x = { a = 36 }
  }

  t.t.t=t
  t[t]=t
  
  local reader=Reader(t,"t")

  local lr=reader:convertToIrTable()
  
  print(dump(lr))
  
  local writer=Writer(test_path)
  
  
  writer:write(lr)
  writer:close()
end


do
  -- signature 15bytes
  -- integrity 6bytes
  -- end_int 4bytes
  -- end_num 8bytes (double)
  -- version 4bytes (int)
  local stream=
  ByteStream(test_path,"r") --

  print(stream:read(15))
  print(stream:read(6))
  print(stream:readLong())
  print(stream:readDouble())
  print(stream:readInt())
 
  stream:close()
  
end