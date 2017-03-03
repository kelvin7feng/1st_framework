
lua_path = "./../script"
package.path = lua_path .."/?.lua;".. package.path

require("setting")
require("dev_share.load")
require("defination.load")
require("common.load")
require("object.load")
require("manager.event_manager")
require("manager.net_manager")

require("center_logic.load")
require("module.protocol")
require("module.center_protocol")

LOG_INFO("load center script succeed...")