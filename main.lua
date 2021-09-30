pcall(function() require "import" end)
-- require module and use global env
-- only use true in the debug env
require "table_serialize" (true)

local dump = dump or print

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
  
  require "table_serialize" 

  
  local t = {
    test=13,
    aaa="6767",
    [676]=4646,
    t = {},
    a = "t",
    
    cc=function ()
    end,
    x = { a = 36 }
  }

  t.t.t=t

  local reader=table_serialize.Reader(t,"t")

  local lr=reader:convertToIrTable()


  local writer=table_serialize.Writer(test_path)


  writer:write(lr)
  writer:close()

  
end




do
  -- signature 15bytes
  -- integrity 6bytes
  -- end_int 8bytes
  -- end_num 8bytes (double)
  -- version 4bytes (int)
  local stream=
  ByteStream(test_path,"r") --

  --stream:read(15)
  --  (stream:read(6))
  --  (stream:readLong())
  --  (stream:readDouble())
  --  (stream:readInt())

  stream:close()

end


do
  local reader=Reader(test_path,"rb")

  local lr=reader:convertToIrTable()


  local source_table=IrConvert.convertIrToTable(lr)

  print(dump(source_table))
end

do
  local String = String or function() end

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

  local binary=Serialize.serialize(
  t,"wb",test_path)


  print(binary)
end


do
  local lr=Serialize.unSerialize(test_path,"rb")
  print(dump(lr))
end