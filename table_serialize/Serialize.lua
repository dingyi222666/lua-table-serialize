local _M = {}


setmetatable(_M,_M)

--[[
serialize a table
mode:
 l return lr table
 b return binary (string)
 wb (must has path) return binary and write to file
 
 @param table input table
 @param mode serialize mode 
 @param path if not null,write binary to path
]]
_M.serialize=function(table,mode,path)
  return ({
    l=function()
      local lr=table_serialize.Reader(table,"t"):convertToIrTable()
      return lr
    end,
    b=function()
      local lr=table_serialize.Reader(table,"t"):convertToIrTable()
      local binary=table_serialize.Writer(nil,"stri")
      :write(lr)
      .__io
      .__io
      :getContent()

      return binary

    end,
    wb=function()
      local lr=table_serialize.Reader(table,"t"):convertToIrTable()
      table_serialize.Writer(path)
      :write(lr)
      :close()
      local file=io.open(path,"r")
      local binary=file:read("*a")
      file:close()
      return binary
    end,
  })[mode]()

end


--[[
unserialize a table
mode:
 lb unserialize binary to lr table
 b unserialize binary to table
 rb (must has path) read binary file and unserialize to table
 rlb (must has path) read binary file and unserialize to lr table
 
 @param table input table
 @param mode unserialize mode 
 @param path if not null,read binary from path
]]
_M.unSerialize=function(table,mode)
  return ({
    lb=function()
      local lr=table_serialize.Reader(table,"b"):convertToIrTable()
      return lr
    end,
    b=function()
      local lr=table_serialize.Reader(table,"b"):convertToIrTable()
      return table_serialize.IrConvert.convertIrToTable(lr)
    end,  
    rlb=function()
      local lr=table_serialize.Reader(table,"rb"):convertToIrTable()
      return lr
    end,
    rb=function()
      local lr=table_serialize.Reader(table,"rb"):convertToIrTable()
      return table_serialize.IrConvert.convertIrToTable(lr)  
    end,
  })[mode]()


end

return _M