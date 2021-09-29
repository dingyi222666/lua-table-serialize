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

  local function childScan(tab)
    visited[tab]=true
    local function check(k,v)
      for k,v in ipairs{k,v} do
        if type(v)=="table" then
          if visited[v]==nil then
            visited[v]=true
            table.insert(result,v)
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
  table.clear(visited)
  return result

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
    signature = self.__stream:read(15),
    integrity = self.__stream:read(6),
    end_int = self.__stream:readLong(),
    end_num = self.__stream:readDouble(),
    version = self.__stream:readInt()
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

  local table_pool_size=self.__stream:readInt()

  for i=1,table_pool_size do
    
    local target = {
      constant={},
      description={}
    }
    table.insert(result,target)

    --read constant

    local constant_pool_size = self.__stream:readInt()

    for i=1,constant_pool_size do
      local constant_type = self.__stream:readByte() -- read 1 byte to get type

      local value =(({
        [0x4]=function() --number
          local number_type = self.__stream:readByte() -- read 1 byte to get number type

          if number_type == 0x2 then
            return self.__stream:readDouble()
           else
            return self.__stream:readLong()
          end

        end,
        [0x5]=function() --string
          local string_len = self.__stream:readInt()
          return self.__stream:read(string_len)
        end,
        [0x6]=function() --boolean
          return self.__stream:readByte() == 0x1
        end,
        [0x7]=function() -- function
          local string_len = self.__stream:readInt()
          local byte_code = self.__stream:read(string_len)
          local func=load(byte_code,"ltb_func","bt")
          return func
        end
      })[constant_type]())

      table.insert(target.constant,value)
    end

    --read description

    local description_size = self.__stream:readInt()

    for i = 1, description_size do
      local _target = {}
      for i=1,2 do
        local description_type=self.__stream:readByte()
        if description_type == 0x8 then
          _target[i] = { constant = true , index = self.__stream:readInt() }
         else
          _target[i]={reference=true,type='table',pool_index=self.__stream:readInt()}
        end
      end
      table.insert(target.description,_target)
    end

  end

  return result

end

_M.__convertToIrTable=function(self)
  self.__stream=table_serialize.ByteStream(self.__content,"strb")

  local lr={
    header=self:readHeader(),
    tablepool=self:readTablePool()
  }
  self.__stream:close()
  return lr
end


_M._convertToIrTable=function(self)
  local tab=self.__content

  --first scan

  local childTables=self:scanTable(tab)

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
  local tablepool={}
  for _,child in ipairs(childTables) do
    local target={
      constant={},
      description={},
    }
    local constant_check = {}
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
          constant_check[k]=#target.constant+1
          table.insert(target.constant,k)
        end
      end
      if check_result[2]==0x1 then
        if not constant_check[v] then
          constant_check[v]=#target.constant+1
          table.insert(target.constant,v)
        end
      end
      table.insert(target.description,
      {
        buildConstant(constant_check[k]) or buildReference(k),
        buildConstant(constant_check[v]) or buildReference(v),
      })
      ::CONTINUE::
    end
    table.insert(result.tablepool,target)
    tablepool[child]=#result.tablepool
  end

  --第一次扫描完成

  --第二次扫描


  for _,pool in pairs(result.tablepool) do
    for valuek,values in pairs(pool.description) do
      for k,v in pairs(values) do
        if type(v)~="table" then
          goto CONTINUE
        end
        if v.reference~=true then
          goto CONTINUE
        end
        if type(v.value)=="table" then
          values[k]={reference=true,type='table',pool_index=tablepool[v.value]}
        end
        ::CONTINUE::
      end
    end

  end

  return result
end

return _M