UserManager = class()

function UserManager:ctor()

	self.m_tbUserDataPool = {};
	self.m_objCurrentUser = nil;

	G_EventManager:Register(EVENT_ID.LOGIC_EVENT.ON_REGISTER, self.OnRegister, self)
end

-- 请求处理完毕提交数据变化处理
function UserManager:Commit()

	local objUser = self:GetCurrentUserObject()
	if objUser and objUser:IsDirty() then
		LOG_DEBUG("user data is dirty, commit change")
		local nUserId = objUser:GetUserId()
		self:SynchronizeToDB(nUserId)
		objUser:SetDirty(false)
		self:ResetCurrentUserObject()
	end
end

-- 同步玩家数据到数据库里
function UserManager:SynchronizeToDB(nUserId)
	local objUser = self:GetUserObject(nUserId);
	local tbGameData = objUser:GetGameData();
	G_GameDataRedis:SetValue(0, 0, nUserId, tbGameData);
end

-- 同步玩家数据到数据库里
function UserManager:SaveUserData(objUser)
	if objUser and objUser:IsDirty() then
		LOG_DEBUG("UserManager:SaveUserData...")
		local tbGameData = objUser:GetGameData();
		G_GameDataRedis:SetValue(0, 0, objUser:GetUserId(), tbGameData);
	end
end

-- 注册成功事件
function UserManager:OnRegister(tbParam)
	LOG_DEBUG("User OnRegister Event...")
end

-- 释放玩家数据对象
function UserManager:ReleaseUserObject(nUserId)
	if self.m_tbUserDataPool[tostring(nUserId)] then
		self.m_tbUserDataPool[tostring(nUserId)] = nil;
		LOG_DEBUG("UserManager:ReleaseUserObject ...." .. nUserId)
	end 
end

-- 缓存玩家数据对象
function UserManager:CacheUserObject(tbGameData)
	local nUserId = tbGameData[GAME_DATA_TABLE_NAME.BASE_INFO][GAME_DATA_FIELD_NAME.BaseInfo.USER_ID];
	local objUser = UserData:new(tbGameData);
	self.m_tbUserDataPool[tostring(nUserId)] = objUser;
end

-- 检查玩家数据对象是否被缓存
function UserManager:IsUserObjectCache(nUserId)
	local objUser = self:GetUserObject(nUserId);
	if objUser then
		return true;
	else
		return false;
	end
end

-- 获取玩家数据对象
function UserManager:GetUserObject(nUserId)
	return self.m_tbUserDataPool[tostring(nUserId)];
end

-- 设置当前请求的玩家数据对象
function UserManager:SetCurrentUserObject(nUserId)
	self.m_objCurrentUser = self:GetUserObject(nUserId);
	LOG_DEBUG("SetCurrentUserObject:" .. nUserId)
	if not self.m_objCurrentUser then
		LOG_ERROR("nUserId " .. nUserId .. " is nil")
	end
	--LOG_TABLE(self.m_objCurrentUser);
end

-- 设置当前请求的玩家数据对象
function UserManager:GetCurrentUserObject()
	return self.m_objCurrentUser;
end

-- 置空当前请求的玩家数据对象
function UserManager:ResetCurrentUserObject()
	self.m_objCurrentUser = nil;
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
	tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID] = nUserId;

	local tbFriendInfo = DATABASE_TABLE_FIELD[DATABASE_TABLE_NAME.GAME_DATA][GAME_DATA_TABLE_NAME.FRIEND_INFO];

	tbGameData[GAME_DATA_TABLE_NAME.BASE_INFO] = tbBaseInfo;
	tbGameData[GAME_DATA_TABLE_NAME.FRIEND_INFO] = tbFriendInfo;

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

	LOG_INFO("Register tbParam:" .. json.encode(tbParam));
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
	G_EventManager:PostEvent(EVENT_ID.LOGIC_EVENT.ON_REGISTER, tbParam);

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
function UserManager:CheckUserDataStatus(nHandlerId, nUserId)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;

	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		LOG_ERROR("Login Param of UserId is Error ");
		return nErrorCode;
	end

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
	self:CacheUserObject(tbGameData)
	G_GlobalConfigManager:IncrementGlobalUserId()
	G_NetManager:SetHandlerId(nUserId, nHandlerId);
	G_NetManager:SetUserId(nHandlerId, nUserId);
	G_RegisterRedis:SetValue(0, 0, tbUserInfo.DeviceId, nUserId);
	G_AccountRedis:SetValue(0, 0, nUserId, tbUserInfo);
	G_GameDataRedis:SetValue(nUserId, EVENT_ID.GET_ASYN_DATA.REGISTERING, nUserId, tbGameData);
end

G_UserManager = UserManager:new()