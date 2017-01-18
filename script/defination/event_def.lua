
-- 事件定义
-- 每一类型事件分配100个事件id

EVENT_ID =  {
	-- 系统事件, 1-100
	SYSTEM	= 
	{
		LOGIN_DIRECT			=   1,
		GET_DEVICE_ID			=   2,
		REGISTERING	 			=   3,
		GET_GAME_DATA 			=   4,
		ENTER_GAME				=	5,
		LOGIC_GET_GAME_DATA		=	6,
	},

	-- 全局配置事件, 101-200
	GLOBAL_CONFIG =
	{
		GET_USER_GLOBAL_ID      =    101
	} 

}

-- 事件名称
EVENT_NAME = {
	OnRegister					= "OnRegister",
	OnLogin						= "OnLogin"
}