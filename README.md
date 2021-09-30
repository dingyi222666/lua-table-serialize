lua-table-serialize
==========

This is a lua table serialize libraray,convert table to binary.

Requirements
------------
        lua >= 5.3

API
---

This package has the following modules:
  * `lrConvert`
  Convert lr table to source table.
  * `Reader`
   Read binary file or source table convert to lr table.
  * `Writer`
   Convert Ir table to binary file.
  * `ByteStream`
    Framework module, read or write byte in lua.
  * `Serialize`
    Integration modules to quickly serialize/unserialize table.
  
They are inside table `table_serialize`,also use this code to import global env.
```lua
require 'table_serialize' (true)
```

Quick use `table_serialize.Serialize` to serialize/unserialize table,so I only list this module api.
 
* `Serialize.serialize(table,mode,path)`
serialize a table.
mode:
    * `l` return lr table
    * `b` return binary (string)
    * `wb` (must has path) return binary and write to file

 param `table` input table.
 param `mode` serialize mode.
 param `path` if not null,write binary to path.


* `Serialize.unserialize(table,mode)`
unserialize a table.
mode:
    * `lb` unserialize binary to lr table.
    * `b` unserialize binary to table.
    * `rb` (must has path) read binary file and unserialize to table.
    * `rlb` (must has path) read binary file and unserialize to lr table.
 
 param `table` binary path or binary (string).
 param `mode` unserialize mode.


Usage
--------

**Code example for serialize a table**
```lua
require "table_serialize" 

local binary=Serialize.serialize(t,"wb",test_path)

print(binary)
```


**Unserialize table**


```lua
local source_table=Serialize.unSerialize("test path","rb")
print(source_table)
```
more example see [`main.lua`](https://github.com/dingyi222666/lua-table-serialize/blob/main/main.lua).
