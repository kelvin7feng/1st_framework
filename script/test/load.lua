package.path = lua_path.."/test/?.lua;"..package.path

require("card_helper_test")

if not DEBUG_SWITCH then
	return;
end

-- G_CardHelperTest:TestGetPoint();
-- G_CardHelperTest:TestBull();
-- G_CardHelperTest:TestCompare();