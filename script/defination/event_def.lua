
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
	}

}

-- 事件名称
EVENT_NAME = {
	OnRegister					= "OnRegister",
	OnLogin						= "OnLogin"
}