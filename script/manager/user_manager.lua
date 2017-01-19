UserManager = class()

function UserManager:ctor()
	self.m_tbUserDataPool = {};
	G_EventManager:Register(EVENT_NAME.OnRegister, self.OnRegister, self)
end

function UserManager:OnRegister(tbParam)
	LOG_DEBUG("User OnRegister Event...")
end

function UserManager:CacheUserObject(nUserId, tbGameData)
	local objUser = UserData:new(nUserId, tbGameData);
	self.m_tbUserDataPool[tostring(nUserId)] = objUser;
	
	LOG_TABLE(tbGameData);
end

function UserManager:GetUserObject(nUserId)
	return self.m_tbUserDataPool[tostring(nUserId)];
end

function UserManager:GetInitUser(tbParam)
	local tbUserInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE.ACCCUNT].USER_INFO;
	tbUserInfo.UserId = G_GlobalConfigManager:GetUserGlobalId();
	tbUserInfo.DeviceId = tbParam.device_id;
	tbUserInfo.RegisterIp = self.ip;
	
	return tbUserInfo;
end

function UserManager:GetInitGameData(nUserId)

	local tbGameData = {}

	local tbBaseInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE.GAME_DATA].BASE_INFO;
	tbBaseInfo.UserId = nUserId

	tbGameData["BaseInfo"] = tbBaseInfo;

	return tbGameData;
end

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

	LOG_DEBUG("register Param:" .. json.encode(tbParam))
	strIp = tbParam.ip;
	if not IsString(strIp) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");
		return nErrorCode
	end

	strDeviceId = tbParam.device_id;
	if not IsString(strDeviceId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strDeviceId is Error ")
		return nErrorCode
	end

	tbUserInfo = self:GetInitUser(tbParam);
	nUserId = tbUserInfo.UserId;

	tbGameData = self:GetInitGameData(nUserId);
	self:RegisterProcess(nUserId, nHandlerId, tbUserInfo, tbGameData)
	nErrorCode = ERROR_CODE.SYSTEM.USER_REGISTERING;
	G_EventManager:PostEvent(EVENT_NAME.OnRegister, tbParam);

	return nErrorCode
end

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
	tbRetInfo.user_id = nUserId;
	tbRetInfo.token = "xxxxxx";
	tbRetInfo.logic_gateway_ip = LOGIC_GATEWAY_IP;
	tbRetInfo.logic_gateway_port = LOGIC_GATEWAY_PORT;

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbRetInfo;
end

function UserManager:CheckRegisterParam(tbParam)
	local strIp = nil;
	local strDeviceId = nil;

	if not IsTable(tbParam) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param is Error ");
		return nErrorCode
	end

	strIp = tbParam.ip;
	if not IsString(strIp) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");
		return nErrorCode
	end

	strDeviceId = tbParam.device_id;
	if not IsString(strDeviceId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strDeviceId is Error ")
		return nErrorCode
	end

	return ERROR_CODE.SYSTEM.OK
end

function UserManager:CheckRegisterInfo(tbParam)
	local nErrorCode = self:CheckRegisterParam(tbParam);
	if IsOkCode(tbParam) then
		LOG_DEBUG("CheckRegisterInfo is Ok...")
	end
	return nErrorCode;
end

function UserManager:CheckUserInfo(nHandlerId, tbParam)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local nUserId = nil

	if not IsTable(tbParam) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Login Param is Error ");
		return nErrorCode;
	end

	nUserId = tbParam.user_id;
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

function UserManager:RegisterProcess(nUserId, nHandlerId, tbUserInfo, tbGameData)
	G_GlobalConfigManager:IncrementGlobalUserId()
	self:CacheUserObject(nUserId, tbGameData)
	G_NetManager:SetHandlerId(nUserId, nHandlerId);
	G_RegisterRedis:SetValue(0, 0, tbUserInfo.DeviceId, nUserId);
	G_AccountRedis:SetValue(0, 0, nUserId, tbUserInfo);
	G_GameDataRedis:SetValue(nUserId, EVENT_ID.GET_ASYN_DATA.REGISTERING, nUserId, tbGameData);
end

G_UserManager = UserManager:new()