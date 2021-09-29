local _M={}

setmetatable(_M,_M)


_M.convertIrToTable=function(lr)

  --convert必须要两次扫描 最后返回tablepool[1]

  local function constantToValue(value,parent)
    if value.constant==true then
      return parent.constant[value.index]
    end
    return value
  end
  local table_pool = {}

  for _,child in ipairs(lr.tablepool) do
    local target = {}
    for _,v in pairs(child.description) do
      local key=constantToValue(v[1],child)
      local value=constantToValue(v[2],child)
      target[key]=value
    end
    table.insert(table_pool,target)
  end

  for _,child in ipairs(table_pool) do
    for k,v in pairs(child) do
      if type(k)=="table" and k.reference==true then
        child[k]=nil
        k=table_pool[k.pool_index]
        child[k]=v
      end
      if type(v)=="table" and v.reference==true then
        v=table_pool[v.pool_index]
        child[k]=v
      end
    end
  end

  return table_pool[1] -- main table

end

return _M