require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"

--使用小端模式


require "table_serialize" (true) --导入模块 并启用全局环境

do
  local *autoClose=ByteStream("/sdcard/test.txt","w")
  :writeInt(1243)
end

do
  local *stream=
  ByteStream("/sdcard/test.txt","r") --

  print(stream:readInt())

  print("end")
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
  
  local *writer=Writer("/sdcard/test.txt")
  
  
  writer:write(lr)
end


do
  -- signature 15bytes
  -- integrity 6bytes
  -- end_int 4bytes
  -- end_num 8bytes (double)
  -- version 4bytes (int)
  local *stream=
  ByteStream("/sdcard/test.txt","r") --

  print(stream:read(15))
  print(stream:read(6))
  print(stream:readLong())
  print(stream:readDouble())
  print(stream:readInt())

  
end