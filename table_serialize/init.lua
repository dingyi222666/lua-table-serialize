local ByteStream = require "table_serialize.ByteStream"
local Reader = require "table_serialize.Reader"
local Writer = require "table_serialize.Writer"
local IrConvert = require "table_serialize.IrConvert"
local Serialize = require "table_serialize.Serialize"


table_serialize = {
  ByteStream = ByteStream,
  Reader = Reader,
  Writer = Writer,
  IrConvert = IrConvert,
  Serialize = Serialize
}

table.clone = table.clone or function(target)
  local result = {}

  local clone_tables={
    [target]=result
  }

  for k,v in pairs(target) do
    if type(v)=="table" then
      local _v=clone_tables[v] or table.clone(v)
      clone_tables[v]=_v
      v=_v
    end
    if type(k)=="table" then
      local _k=clone_tables[k] or table.clone(k)
      clone_tables[k]=_k
      k=_k
    end

    result[k]=v
  end
  return result
end


return function(use_env)
  if use_env==true then
    _G.ByteStream,_G.Reader,_G.Writer,
    _G.IrConvert,_G.Serialize =
    ByteStream,Reader,Writer,
    IrConvert,Serialize
  end
end 