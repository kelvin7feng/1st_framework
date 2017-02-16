ERROR_CODE = {}

-- 系统错误码,0-10000
ERROR_CODE.SYSTEM   = 
{
	OK							=  0,
	UNKNOWN_ERROR				=  1,
	PARAMTER_ERROR  			=  2,
	USER_DATA_NIL   			=  3,
	USER_NO_REGISTER   			=  4,
	USER_REGISTERING   			=  5
}

-- 玩家基本信息错误码, 10001-10100
ERROR_CODE.USER_BASE_INFO   = 
{
	AVATAR_ID_IS_OUT_OF_RANGE	=	10001,		--	头像ID超出范围
	SEX_IS_OUT_OF_RANGE			=	10002,		--	性别超出范围
	INVITER_ID_IS_OUT_OF_RANGE	=	10003,		--	超出范围
	INVITER_ID_IS_NOT_EMPTY		=	10004,		--	已填写过邀请人了
	INVITER_ID_IS_ONESELF		=	10005,		--	邀请人id不能为自己
	PHONE_NO_IS_ILLEGAL			=	10006,		--	电话号码格式不对
	HAVE_BEEN_BOUND				=	10007,		--	已经绑定过了
}