
lua_path = "./../script"
package.path = lua_path .."/?.lua;".. package.path

require("defination.load")
require("common.load")
require("object.load")
require("manager.load")

require("module.protocol")
require("module.login_protocol")

G_GlobalConfigManager:Init();

LOG_INFO("load login script succeed...")