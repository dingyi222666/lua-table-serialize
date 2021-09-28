
local _M={}

setmetatable(_M,_M)

_M.__call=function(self,path)
  local result=table.clone(self)

  result.__path=path
  result.__io=table_serialize.ByteStream(path,"w")
  return setmetatable(result,result)
end

_M.writeHeader=function(self,header)
  --write header
  self.__io:writeString(header.signature)
  self.__io:writeString(header.integrity)
  self.__io:writeLong(header.end_int)
  self.__io:writeDouble(header.end_num)
  self.__io:writeInt(header.version)

end

_M.getConstantType=function(value)
  return ({
    number=0x4,
    boolean = 0x6,
    string = 0x5,
    ['function'] = 0x7,
    -- table 0x9
    -- const reference 0x8
  })[type(value)]

end

_M.writeConstant=function(self,const)
  return ({
    number=function()
      if math.type(const)=="float" then
        self.__io:writeByte(0x2)
        self.__io:writeDouble(const)
       else
        self.__io:writeByte(0x1)
        self.__io:writeLong(const)
      end
    end,
    boolean = function()
      self.__io:writeByte(const==true and 1 or 0)
    end,
    string = function()
      self.__io:writeInt(#const) --write string size
      self.__io:writeString(const)
    end,
    ['function'] = function()
      local content=string.dump(const)
      self.__io:writeInt(#content)
      self.__io:writeString(content)
    end,
  })[type(const)]()
end

_M.writeTable=function(self,tab)
  self.__io:writeInt(#tab.constant) -- constant pool size
  for _,v in ipairs(tab.constant) do
    self.__io:writeByte(self.getConstantType(v))
    self:writeConstant(v)
  end
  self.__io:writeInt(#tab.description)
  for _,v in ipairs(tab.description) do
    for _,v in ipairs(v) do      
      if v.index then
        self.__io:writeByte(0x8)
        self.__io:writeInt(v.index)
       else
        self.__io:writeByte(0x9)
        self.__io:writeInt(v.pool_index)
      end
    end
  end
end

_M.writeTablePool=function(self,list)
  self.__io:writeInt(#list) --write pool size (4 byte)
  for _,v in ipairs(list) do
    self:writeTable(v)
  end
end

_M.write=function(self,lr)
  self:writeHeader(lr.header)
  self:writeTablePool(lr.tablepool)
end

_M.__close=function(self)

  if self.__io then
    self.__io:close()
  end
end

_M.close=_M.__close


return _M