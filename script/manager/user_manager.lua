UserManager = class()

function UserManager:ctor()
	self.m_tbUser = {};
	self.m_nGlobalUserId = 100001;
end

function UserManager:IncrementGlobalUserId()
	self.m_nGlobalUserId = self.m_nGlobalUserId + 1;
end

function UserManager:GetUser(nUserId)
	LOG_INFO("User id:" .. nUserId)
	LOG_INFO("self.m_tbUser:" .. json.encode(self.m_tbUser));
	return self.m_tbUser[tostring(nUserId)] or nil;
end

function UserManager:CacheUser(nUserId, tbUserInfo)
	if IsString(tbUserInfo) then
		tbUserInfo = json.decode(tbUserInfo);
	end

	self.m_tbUser[tostring(nUserId)] = tbUserInfo;
end

function UserManager:GetInitUser(tbParam)
	local tbUserInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE.ACCCUNT].USER_INFO;
	tbUserInfo.UserId = self.m_nGlobalUserId;
	tbUserInfo.DeviceId = tbParam.device_id;
	tbUserInfo.RegisterIp = self.ip;
	
	return tbUserInfo;
end

function UserManager:Register(nHandlerId, tbParam)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local strIp = nil;
	local nUserId = nil;
	local tbUserInfo = nil;
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

	--to do:检查是否有注册过
	tbUserInfo = self:GetInitUser(tbParam);
	nUserId = tbUserInfo.UserId;
	self:RegisterProcess(nUserId, nHandlerId, tbUserInfo)
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode, nUserId
end

function UserManager:Login(nUserId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local tbUserInfo = G_UserManager:GetUser(nUserId);
	LOG_INFO("tbUserInfo:" .. json.encode(tbUserInfo))
	if not tbUserInfo or nUserId ~= tbUserInfo.UserId then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbUserInfo;
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
	local tbUserInfo = self:GetUser(nUserId);
	if not tbUserInfo then
		LOG_INFO("User Info does not cache...")
		G_AccountRedis:GetValue(nUserId, EVENT_TYPE.SYSTEM.LOGIN, nUserId);
		nErrorCode = ERROR_CODE.SYSTEM.USER_DATA_NIL;
		return nErrorCode;
	end

	LOG_INFO("User Info have been cached...")
	OnRedisRespone(nUserId, EVENT_TYPE.SYSTEM.LOGIN, json.encode(tbUserInfo));
end

function UserManager:RegisterProcess(nUserId, nHandlerId, tbUserInfo)
	self:IncrementGlobalUserId()
	self:CacheUser(nUserId, tbUserInfo)
	G_NetManager:SetHandlerId(nUserId, nHandlerId)
	G_AccountRedis:SetValue(nUserId, EVENT_TYPE.SYSTEM.REGISTER, nUserId, tbUserInfo);
end

G_UserManager = UserManager:new()