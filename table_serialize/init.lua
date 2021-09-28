local ByteStream=require "table_serialize.ByteStream"
local Reader=require "table_serialize.Reader"
local Writer = require "table_serialize.Writer"

local Serialize  --

return function(use_env)
  if use_env then
    _G.ByteStream,_G.Reader,_G.Writer =
    ByteStream,Reader,Writer
  else
   
  end
  table_serialize = {
    ByteStream=ByteStream,Reader=Reader,Writer=Writer
  }
end 