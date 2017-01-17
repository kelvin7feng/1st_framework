
-- 数据库表名索引
DATABASE_TABLE = 
{
	GLOBAL = 1,
	ACCCUNT = 2,
	REGISTER = 3,
	GAME_DATA = 4		
}

-- 数据库名字
MAP_DATABSE_TABLE_KEY = 
{
	[DATABASE_TABLE.GLOBAL] 			=  "global",
	[DATABASE_TABLE.ACCCUNT] 			=  "account",
	[DATABASE_TABLE.REGISTER] 			=  "register",
	[DATABASE_TABLE.GAME_DATA] 			=  "gamedata"
}

-- 数据库字段
DATABASE_TABLE_FIELD = 
{
	[DATABASE_TABLE.GLOBAL] 			=  
	{
		USER_ID							=  10000001
	},

	[DATABASE_TABLE.ACCCUNT] 			=  
	{
		USER_INFO						= 
		{
			UserId 						= 0,		-- 玩家Id
			DeviceId					= "",		-- 设备Id
			RegisterIp					= ""		-- 注册Ip	
		}
	},

	[DATABASE_TABLE.GAME_DATA] 			=  
	{
		BASE_INFO						= 
		{
			UserId 						= 0,		-- 玩家Id
			Sex							= 0,		-- 性别
			Name						= "Guest",	-- 名字
			Diamond						= 0,		-- 钻石
			Gold						= 5000		-- 金币
		}
	}
}