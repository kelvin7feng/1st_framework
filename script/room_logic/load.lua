package.path = lua_path.."/room_logic/?.lua;"..package.path

require("class.base_table")
require("class.bull_fighting_table")

require("game.game_base")
require("game.bull_fighting")

require("tool.id_generator")
require("tool.shuffler")
require("tool.bull_fighting_shuffler")

require("manager.room_manager")