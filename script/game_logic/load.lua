package.path = lua_path.."/game_logic/?.lua;"..package.path

require("user_info.user_info_logic")
require("user_info.user_info_protocol")

require("store.store_logic")
require("store.store_protocol")

require("fight_the_landlord.fight_the_landlord_logic")
require("fight_the_landlord.fight_the_landlord_protocol")

require("friend.friend_logic")
require("friend.friend_protocol")

require("service.room_service")

require("manager.game_manager")
require("manager.game_protocol")