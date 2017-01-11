UserManager = class()

function UserManager:ctor()
	self.m_tbUser = {};
	self.m_nGlobalUserId = 100001;
end

function UserManager:IncrementGlobalUserId()
	self.m_nGlobalUserId = self.m_nGlobalUserId + 1;
end

function UserManager:GetUser(nUserId)
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
	local nUserId = nil
	local tbUserInfo = nil
	local strDeviceId = nil;

	if not IsTable(tbParam) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");

		--goto Exit0;
		return 0;
	end

	strIp = tbParam.ip;
	if not IsString(strIp) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strIp is Error ");

		--goto Exit0;
		return 0;
	end

	strDeviceId = tbParam.device_id;
	if not IsString(strDeviceId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Register Param of strDeviceId is Error ")

		--goto Exit0;
		return 0;
	end

	--to do:检查是否有注册过
	tbUserInfo = self:GetInitUser(tbParam);
	nUserId = tbUserInfo.UserId;
	self:RegisterProcess(nUserId, nHandlerId, tbUserInfo)

	nErrorCode = ERROR_CODE.SYSTEM.OK;
--::Exit0::

	return nErrorCode, nUserId
end

function UserManager:RegisterProcess(nUserId, nHandlerId, tbUserInfo)
	self:IncrementGlobalUserId()
	self:CacheUser(nUserId, tbUserInfo)
	LOG_INFO("nHandlerId:" .. nHandlerId);
	LOG_INFO("Cache User:" .. json.encode(tbUserInfo));
	LOG_INFO("User tb:" .. json.encode(self.m_tbUser));
	G_NetInfoManager:SetHandlerId(nUserId, nHandlerId)
	G_AccountRedis:SetValue(nUserId, EVENT_TYPE.SYSTEM.REGISTER, nUserId, tbUserInfo);
end

G_UserManager = UserManager:new()