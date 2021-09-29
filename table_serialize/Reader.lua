local _M={}

setmetatable(_M,_M)

_M.__call=function(self,content,mode)
  local result=table.clone(self)

  result.__content=content
  result.__mode=mode
  return setmetatable(result,result)
end


_M.scanTable=function(self,tab)
  local result={tab}

  local visited={}
  
  local indexed={[tab]=1}
  local len=1
  local function childScan(tab)
    visited[tab]=true
    local function check(...)
      for k,v in ipairs{...} do
        if type(v)=="table" then
          if visited[v]==nil then
            visited[v]=true
            table.insert(result,v)
            len=len+1
            indexed[v]=len
            childScan(v)
          end
        end
      end
    end

    for k,v in pairs(tab) do
      check(k,v)
    end

  end


  childScan(tab)
  
  return result,indexed

end

local function checkConstant(value)
  local type=type(value)
  if type=="userdata" or type=="thread" then
    return 0x3
   elseif type=="table" then
    return 0x2
  end
  return 0x1
end

local function buildReference(t)
  return {value=t,reference=true}
end

local function buildConstant(index)
  return index and {constant=true,index=index}or nil
end

_M.convertToIrTable=function(self)
  if self.__mode=="rb" then
    local file=io.open(self.__content,"r+")
    self.__content=file:read("*a")
    file:close()
    return self:__convertToIrTable()
   elseif self.__mode=="b" then
    return self:__convertToIrTable()
   elseif self.__mode=="t" then
    return self:_convertToIrTable()
  end
end

_M.readHeader=function(self,chunk)
  local target_header = {
    signature = '\27LuaTableBinary';
    integrity = '\25\147\13\10\26\10';
    end_int = 0x5678;
    end_num = 370.5;
    version = 0x1;
  }

  local reader_header = {
    signature = self.__io:read(15),
    integrity = self.__io:read(6),
    end_int = self.__io:readLong(),
    end_num = self.__io:readDouble(),
    version = self.__io:readInt()
  }

  assert(target_header.signature==reader_header.signature)
  assert(target_header.integrity==reader_header.integrity)
  assert(target_header.end_int==reader_header.end_int)
  assert(target_header.end_num==reader_header.end_num)
  assert(target_header.version==reader_header.version)
  print("check header pass")
  return reader_header
end

_M.readTablePool=function(self)
  local result = {}

  local table_pool_size=self.__io:readInt()

  for i=1,table_pool_size do
    
    local target = {
      constant={},
      description={}
    }
    table.insert(result,target)

    --read constant

    local constant_pool_size = self.__io:readInt()

    for i=1,constant_pool_size do
      local constant_type = self.__io:readByte() -- read 1 byte to get type

      local value =(({
        [0x4]=function() --number
          local number_type = self.__io:readByte() -- read 1 byte to get number type

          if number_type == 0x2 then
            return self.__io:readDouble()
           else
            return self.__io:readLong()
          end

        end,
        [0x5]=function() --string
          local string_len = self.__io:readInt()
          return self.__io:read(string_len)
        end,
        [0x6]=function() --boolean
          return self.__io:readByte() == 0x1
        end,
        [0x7]=function() -- function
          local string_len = self.__io:readInt()
          local byte_code = self.__io:read(string_len)
          local func=load(byte_code,"ltb_func","bt")
          return func
        end
      })[constant_type]())

      table.insert(target.constant,value)
    end

    --read description

    local description_size = self.__io:readInt()

    for i = 1, description_size do
      local _target = {}
      for i=1,2 do
        local description_type=self.__io:readByte()
        if description_type == 0x8 then
          _target[i] = { constant = true , index = self.__io:readInt() }
         else
          _target[i]={reference=true,type='table',pool_index=self.__io:readInt()}
        end
      end
      table.insert(target.description,_target)
    end

  end

  return result

end

_M.__convertToIrTable=function(self)
  self.__io=table_serialize.ByteStream(self.__content,"strb")

  local lr={
    header=self:readHeader(),
    tablepool=self:readTablePool()
  }
  self.__io:close()
  return lr
end


_M._convertToIrTable=function(self)
  local tab=self.__content

  --first scan

  local childTables,indexs=self:scanTable(tab)

  local result={
    header = {
      signature = '\27LuaTableBinary';
      integrity = '\25\147\13\10\26\10';
      end_int = 0x5678;
      end_num = 370.5;
      version = 0x1;
    },
    tablepool = {
    }

  }
  
  for index,child in ipairs(childTables) do
    local target={
      constant={},
      description={},
    }
    local constant_check = {}
    local constant_len = 0
    for k,v in pairs(child) do
      local check_result={
        checkConstant(k),checkConstant(v)
      }
      local break_flag=false
      for i=1,2 do
        if check_result[i]==0x3 then
          break_flag=true
          break
        end
      end
      if break_flag then
        goto CONTINUE
      end
      if check_result[1]==0x1 then
        if not constant_check[k] then
          constant_len=constant_len+1
          constant_check[k]=constant_len
          table.insert(target.constant,k)
        end
      end
      if check_result[2]==0x1 then
        if not constant_check[v] then
          constant_len=constant_len+1
          constant_check[v]=constant_len
          table.insert(target.constant,v)
        end
      end
      table.insert(target.description,
      {
        buildConstant(constant_check[k]) or {reference=true,type='table',pool_index=indexs[k]},
        buildConstant(constant_check[v]) or {reference=true,type='table',pool_index=indexs[v]},
      })
      ::CONTINUE::
    end
    table.insert(result.tablepool,target)
    
  end

  --第一次扫描完成

  

  return result
end

return _M