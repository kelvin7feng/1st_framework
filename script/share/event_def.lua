
-- 事件定义
-- 每一类型事件分配100个事件id

EVENT_ID =  {
	-- 异步请求数据事件 1,1000
	GET_ASYN_DATA = 
	{
		GET_DEVICE_ID			=   1,
		REGISTERING	 			=   2,
		GET_GAME_DATA 			=   3,
		LOGIC_GET_GAME_DATA		=	4
	},

	-- 系统事件, 1001-1100
	SYSTEM	= 
	{
		LOGIN 		            =   1001,
		REGISTER 				=   1002
	},

	-- 全局配置事件, 1101-1200
	GLOBAL_CONFIG =
	{
		GET_USER_GLOBAL_ID      =   1101
	},

	-- 全局配置事件, 2001-3000
	LOGIC_EVENT = 
	{
		ON_REGISTER				=   2001
	},

	--[[
	客户端事件定义规则：表名以CLIENT_开头,每个功能占位100个位置,必须紧接前一个功能分配
	--]]

	-- 客户端事件, 10001, 10100
	CLIENT_LOGIN = {
		LOGIN_DIRECT			=   10001,		-- 直接登录
		ENTER_GAME				=	10002		-- 进入游戏
	},

	-- 客户端测试接口事件, 10101， 10200
	CLIENT_TEST = 
	{
		ADD_GOLD				= 	10101,		-- 增加金币
	}
}