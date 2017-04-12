package.path = lua_path.."/common/?.lua;"..package.path

require("json")
require("log")
require("math")
require("public")
require("table")
require("type")

local timer = require("timer")
G_Timer = timer:new();