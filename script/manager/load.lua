package.path = lua_path.."/manager/?.lua;"..package.path

require("redis_manager")
require("event_manager")
require("net_manager")
require("user_manager")
require("game_command_manager")
require("global_config_manager")