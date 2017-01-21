
-- 数据库名字
DATABASE_TABLE_NAME = 
{
	GLOBAL 				=  "global",
	ACCCUNT				=  "account",
	REGISTER 			=  "register",
	GAME_DATA 			=  "gamedata"
}

-- 全局配置字段
DATABASE_TABLE_GLOBAL_FIELD = 
{
	USER_ID								= "UserGlobalId",
}

-- 全局配置默认值
DATABASE_TABLE_GLOBAL_DEFALUT = 
{
	[DATABASE_TABLE_GLOBAL_FIELD.USER_ID] = 100001,
}

-- 游戏数据表名
GAME_DATA_TABLE_NAME = 
{
	USER_INFO							= "UserInfo",
	BASE_INFO							= "BaseInfo"
}

-- 数据字段表
GAME_DATA_FIELD_NAME = {}

-- 用户表数据
GAME_DATA_FIELD_NAME.UserInfo = 
{
	USER_ID									= "UserId",
	DEVICE_ID								= "DeviceId",
	REGISTER_IP								= "RegisterIp",
}

-- 游戏基础字段
GAME_DATA_FIELD_NAME.BaseInfo = 
{
	USER_ID									= "UserId",
	SEX 									= "Sex",
	NAME 									= "Name",
	DIAMOND 								= "Diamond",
	GOLD 									= "Gold"
}

-- 数据库字段,构建该表是为了初始化玩家数据时直接引用
DATABASE_TABLE_FIELD = 
{

	[DATABASE_TABLE_NAME.ACCCUNT] 			=  
	{
		[GAME_DATA_TABLE_NAME.USER_INFO]	= 
		{
			[GAME_DATA_FIELD_NAME.UserInfo.USER_ID]				= 0,		-- 玩家Id
			[GAME_DATA_FIELD_NAME.UserInfo.DEVICE_ID]			= "",		-- 设备Id
			[GAME_DATA_FIELD_NAME.UserInfo.REGISTER_IP]			= ""		-- 注册Ip	
		}
	},

	[DATABASE_TABLE_NAME.GAME_DATA] 		=  
	{
		[GAME_DATA_TABLE_NAME.BASE_INFO]	= 
		{
			[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID] 				 = 0,		-- 玩家Id
			[GAME_DATA_FIELD_NAME.BaseInfo.SEX]					     = 0,		-- 性别
			[GAME_DATA_FIELD_NAME.BaseInfo.NAME]					 = "Guest",	-- 名字
			[GAME_DATA_FIELD_NAME.BaseInfo.DIAMOND]				     = 0,		-- 钻石
			[GAME_DATA_FIELD_NAME.BaseInfo.GOLD]					 = 5000		-- 金币
		}
	}
}