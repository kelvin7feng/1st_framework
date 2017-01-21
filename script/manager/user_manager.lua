UserManager = class()

function UserManager:ctor()

	self.m_tbUserDataPool = {};

	G_EventManager:Register(EVENT_NAME.OnRegister, self.OnRegister, self)
end

-- 注册成功事件
function UserManager:OnRegister(tbParam)
	LOG_DEBUG("User OnRegister Event...")
end

-- 缓存玩家数据对象
function UserManager:CacheUserObject(nUserId, tbGameData)
	local objUser = UserData:new(nUserId, tbGameData);
	self.m_tbUserDataPool[tostring(nUserId)] = objUser;
	
	LOG_TABLE(tbGameData);
end

-- 获取玩家数据对象
function UserManager:GetUserObject(nUserId)
	return self.m_tbUserDataPool[tostring(nUserId)];
end

-- 玩家账号数据初始化
function UserManager:GetInitUser(strDeviceId, strIp)
	local tbUserInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE_NAME.ACCCUNT][GAME_DATA_TABLE_NAME.USER_INFO];
	tbUserInfo[GAME_DATA_FIELD_NAME.UserInfo.USER_ID] = G_GlobalConfigManager:GetUserGlobalId();
	tbUserInfo[GAME_DATA_FIELD_NAME.UserInfo.DEVICE_ID] = strDeviceId;
	tbUserInfo[GAME_DATA_FIELD_NAME.UserInfo.REGISTER_IP] = strIp;
	
	return tbUserInfo;
end

-- 玩家数据初始化
function UserManager:GetInitGameData(nUserId)

	local tbGameData = {}

	local tbBaseInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE_NAME.GAME_DATA][GAME_DATA_TABLE_NAME.BASE_INFO];

	tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID] = nUserId

	tbGameData["BaseInfo"] = tbBaseInfo;

	return tbGameData;
end

-- 注册
function UserManager:Register(nHandlerId, tbParam)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local strIp = nil;
	local nUserId = nil;
	local tbUserInfo = nil;
	local tbGameData = nil;
	local strDeviceId = nil;

	if not IsTable(tbParam) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param is Error ");
		return nErrorCode
	end

	LOG_TABLE("Register tbParam:" .. json.encode(tbParam));
	strDeviceId = tbParam[1]
	strIp = tbParam[2]

	if not IsString(strDeviceId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strDeviceId is Error ")
		return nErrorCode
	end

	if not IsString(strIp) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");
		return nErrorCode
	end

	tbUserInfo = self:GetInitUser(strDeviceId, strIp);
	nUserId = tbUserInfo.UserId;

	tbGameData = self:GetInitGameData(nUserId);
	self:RegisterProcess(nUserId, nHandlerId, tbUserInfo, tbGameData)
	nErrorCode = ERROR_CODE.SYSTEM.USER_REGISTERING;
	G_EventManager:PostEvent(EVENT_NAME.OnRegister, tbParam);

	return nErrorCode
end

-- 进入游戏
function UserManager:EnterGame(nUserId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetUserObject(nUserId);
	if not objUser or nUserId ~= objUser:GetUserId() then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, objUser;
end

-- 登录
function UserManager:Login(nUserId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetUserObject(nUserId);
	if not objUser or nUserId ~= objUser:GetUserId() then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	local tbRetInfo = {}
	table.insert(tbRetInfo, LOGIC_GATEWAY_IP)
	table.insert(tbRetInfo, LOGIC_GATEWAY_PORT)
	table.insert(tbRetInfo, nUserId)
	table.insert(tbRetInfo, "xxxxxx")
	
	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbRetInfo;
end

-- 检查注册的客户端的参数
function UserManager:CheckRegisterParam(tbParam)
	local strIp = nil;
	local strDeviceId = nil;

	if not IsTable(tbParam) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param is Error ");
		return nErrorCode
	end
	
	strDeviceId = tbParam[1]
	strIp = tbParam[2]
	
	LOG_DEBUG("strDeviceId:" .. strDeviceId)
	LOG_DEBUG("strIp:" .. strIp)
	if not IsString(strDeviceId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strDeviceId is Error ")
		return nErrorCode
	end

	
	if not IsString(strIp) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");
		return nErrorCode
	end

	return ERROR_CODE.SYSTEM.OK
end

-- 检查注册数据
function UserManager:CheckRegisterInfo(tbParam)
	local nErrorCode = self:CheckRegisterParam(tbParam);
	if IsOkCode(tbParam) then
		LOG_DEBUG("CheckRegisterInfo is Ok...")
	end
	return nErrorCode;
end

-- 检查玩家信息
function UserManager:CheckUserInfo(nHandlerId, nUserId)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;

	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Login Param of UserId is Error ");
		return nErrorCode;
	end

	-- 映射玩家Id和Handler
	G_NetManager:SetHandlerId(nUserId, nHandlerId);

	-- 如果没有缓存，则需要从数据库里面读取出来，在数据回来后再处理
	local objUser = self:GetUserObject(nUserId);
	if not objUser then
		nErrorCode = ERROR_CODE.SYSTEM.USER_DATA_NIL;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode;
end

-- 注册操作过程
function UserManager:RegisterProcess(nUserId, nHandlerId, tbUserInfo, tbGameData)
	G_GlobalConfigManager:IncrementGlobalUserId()
	self:CacheUserObject(nUserId, tbGameData)
	G_NetManager:SetHandlerId(nUserId, nHandlerId);
	G_RegisterRedis:SetValue(0, 0, tbUserInfo.DeviceId, nUserId);
	G_AccountRedis:SetValue(0, 0, nUserId, tbUserInfo);
	G_GameDataRedis:SetValue(nUserId, EVENT_ID.GET_ASYN_DATA.REGISTERING, nUserId, tbGameData);
end

G_UserManager = UserManager:new()