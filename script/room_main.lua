
lua_path = "./../script"
package.path = lua_path .."/?.lua;".. package.path
bit = require("bit")

require("setting")
require("dev_share.load")
require("defination.load")
require("common.load")
require("object.load")
require("manager.load")
require("room_logic.load")
require("test.load")

require("module.protocol")
require("module.logic_protocol")

G_GlobalConfigManager:Init();

LOG_INFO("load room script succeed...")