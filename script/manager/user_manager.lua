UserManager = class()

function UserManager:ctor()
	self.m_tbUser = {};
	self.m_nGlobalUserId = 100001;
	G_EventManager:Register(EVENT_NAME.OnRegister, self.OnRegister, self)
end

function UserManager:OnRegister(tbParam)
	LOG_INFO("User OnRegister Event...")
end

function UserManager:IncrementGlobalUserId()
	self.m_nGlobalUserId = self.m_nGlobalUserId + 1;
end

function UserManager:GetUser(nUserId)
	LOG_INFO("User id:" .. nUserId)
	LOG_INFO("self.m_tbUser:" .. json.encode(self.m_tbUser));
	if not self.m_tbUser[tostring(nUserId)] then
		return nil
	end

	return self.m_tbUser[tostring(nUserId)].UserInfo or nil;
end

function UserManager:GetUserGameData(nUserId)
	LOG_INFO("User id:" .. nUserId)
	if not self.m_tbUser[tostring(nUserId)] then
		return nil
	end

	return self.m_tbUser[tostring(nUserId)].GameData or nil;
end

function UserManager:CacheUser(nUserId, tbUserInfo, tbGameData)
	if IsString(tbUserInfo) then
		tbUserInfo = json.decode(tbUserInfo);
	end

	if not self.m_tbUser[tostring(nUserId)] then
		self.m_tbUser[tostring(nUserId)] = {}
	end
	self.m_tbUser[tostring(nUserId)].UserInfo = tbUserInfo;
	self.m_tbUser[tostring(nUserId)].GameData = tbGameData;
end

function UserManager:CacheUserGameData(nUserId, tbGameData)
	if IsString(tbUserInfo) then
		tbUserInfo = json.decode(tbUserInfo);
	end

	if not self.m_tbUser[tostring(nUserId)] then
		self.m_tbUser[tostring(nUserId)] = {}
	end
	
	self.m_tbUser[tostring(nUserId)].GameData = tbGameData;
end

function UserManager:GetInitUser(tbParam)
	local tbUserInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE.ACCCUNT].USER_INFO;
	tbUserInfo.UserId = self.m_nGlobalUserId;
	tbUserInfo.DeviceId = tbParam.device_id;
	tbUserInfo.RegisterIp = self.ip;
	
	return tbUserInfo;
end

function UserManager:GetInitGameData(nUserId)
	local tbGameData = DATABASE_TABLE_FIELD[DATABASE_TABLE.GAME_DATA].BASE_INFO;
	tbGameData.UserId = nUserId
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

function UserManager:Login(nUserId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local tbGameData = G_UserManager:GetUserGameData(nUserId);
	LOG_INFO("tbGameData:" .. json.encode(tbGameData))
	if not tbGameData or nUserId ~= tbGameData.UserId then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbGameData;
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
		LOG_INFO("CheckRegisterInfo is Ok...")
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
	local tbUserGameData = self:GetUserGameData(nUserId);
	if not tbUserGameData then
		nErrorCode = ERROR_CODE.SYSTEM.USER_DATA_NIL;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode;
end

function UserManager:RegisterProcess(nUserId, nHandlerId, tbUserInfo, tbGameData)
	self:IncrementGlobalUserId()
	self:CacheUser(nUserId, tbUserInfo, tbGameData);
	G_NetManager:SetHandlerId(nUserId, nHandlerId);
	G_RegisterRedis:SetValue(0, 0, tbUserInfo.DeviceId, nUserId);
	G_AccountRedis:SetValue(0, 0, nUserId, tbUserInfo);
	G_GameDataRedis:SetValue(nUserId, EVENT_ID.SYSTEM.REGISTERING, nUserId, tbGameData);
end

G_UserManager = UserManager:new()