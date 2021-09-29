local _M={}

setmetatable(_M,_M)


local string_io = {
  build=function(self,content)
    local new=table.clone(self)
    new.__content=content
    new.__len=#content
    return new
  end,
  position=1,
  read=function(self,size)
    if self.position+size-1>self.__len then
      return nil
    end
    local result=self.__content
    :sub(self.position,self.position+size-1)

    self.position=self.position+size

    return result

  end,
  close=function(self)
    table.clear(self)
    collectgarbage()
  end
  --not support write
}

_M.__call=function(self,path,mode)
  local result=table.clone(self)
  result.__mode=mode
  
  if mode=="strb" then
    result.__io=string_io:build(path)
   else
    result.__io=io.open(path,mode.."b")
  end
  return setmetatable(result,result)
end

_M.writeString=function(self,str)
  self.__io:write(str)
end

_M.writeByte=function(self,byte)
  self.__io:write(string.char(byte))
end

_M.readByte=function(self)
  
  return utf8.byte(self:read(1))
end

_M.writeDouble=function(self,num)

  local str=("<d"):pack(num)

  self.__io:write(str)
  return self
end

_M.readDouble=function(self,num)
  local str=self.__io:read(8)

  if str==nil then
    return nil
  end

  local _=("<d"):unpack(str)
  return _
end

_M.readFloat=function(self,num)
  local str=self.__io:read(4)

  if str==nil then
    return nil
  end

  local _=("<f"):unpack(str)
  return _
end

_M.readLong=function(self,num)
  local str=self.__io:read(8)

  if str==nil then
    return nil
  end

  local _=("<l"):unpack(str)
  return _
end

_M.read=function(self,num)
  return self.__io:read(num)
end


_M.writeFloat=function(self,num)
  local str=("<f"):pack(num)
  self.__io:write(str)
  return self
end

_M.writeInt=function(self,int)
  local byteIntArray={0,0,0,0} --4 byte to
  byteIntArray[4],byteIntArray[3],
  byteIntArray[2],byteIntArray[1] =
  ((int >> 24) & 0xff) , ((int >> 16) & 0xff),
  ((int >> 8 ) & 0xff) , (int & 0xff)
  for _,v in ipairs(byteIntArray) do
    self.__io:write(string.char(v))
  end
  return self
end



_M.readInt=function(self)
  local str=self.__io:read(4)

  if str==nil then
    return nil
  end
  local byteIntArray={0,0,0,0} --4 byte to
  for i=1,4 do
    byteIntArray[i]=string.byte(str:sub(i,i))
  end

  return ((byteIntArray[4]&0xff)<<24)~((byteIntArray[3]&0xff)<<16)~((byteIntArray[2]&0xff))<<8~((byteIntArray[1]&0xff))

end


_M.writeLong=function(self,num)
  local str=("<l"):pack(num)
  self.__io:write(str)
  return self
end


_M.__close=function(self)

  if self.__io then
    self.__io:close()
  end
end

_M.close=_M.__close


return _M