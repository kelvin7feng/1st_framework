UserInfoProtocol = class()

function UserInfoProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.UPDATE_AVATAR, self.ClientUpdateAvatar, self);
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.UPDATE_SEX, self.ClientUpdateSex, self);
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.UPDATE_INVITER_ID, self.ClientUpdateInviterId, self);
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.UPDATE_NICK_NAME, self.ClientUpdateNickName, self);
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.BINDING_PHONE_NO, self.ClientBindingPhoneNo, self);	
	G_EventManager:Register(EVENT_ID.CLIENT_BASE_INFO.UPDATE_BALANCE, self.ClientUpdateBalance, self);		
end

-- 客户端修改存款协议
function UserInfoProtocol:ClientUpdateBalance(nBalance)
	
	LOG_DEBUG("UserInfoProtocol:ClientSetBalance")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nBalance) then
		LOG_WARN("UserInfoProtocol:ClientSetBalance nBalance is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();

	return G_UserInfoLogic:UpdateBalance(objUser, nBalance);
end

-- 客户端更新头像协议
function UserInfoProtocol:ClientUpdateAvatar(nAvatarId)
	
	LOG_DEBUG("UserInfoProtocol:ClientUpdateAvatar:" .. nAvatarId)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nAvatarId) then
		LOG_WARN("UserInfoProtocol:ClientUpdateAvatar nAvatarId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_UserInfoLogic:UpdateAvatar(objUser, nAvatarId)

	return nErrorCode;
end

-- 客户端更新性别协议
function UserInfoProtocol:ClientUpdateSex(nSex)
	
	LOG_DEBUG("UserInfoProtocol:ClientUpdateSex:" .. nSex)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nSex) then
		LOG_WARN("UserInfoProtocol:ClientUpdateSex nSex is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_UserInfoLogic:UpdateSex(objUser, nSex)

	return nErrorCode;
end

-- 客户端更新性别协议
function UserInfoProtocol:ClientUpdateInviterId(nInviterId)
	
	LOG_DEBUG("UserInfoProtocol:ClientUpdateInviterId:" .. nInviterId)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nInviterId) then
		LOG_WARN("UserInfoProtocol:ClientUpdateInviterId nInviterId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_UserInfoLogic:UpdateInviterId(objUser, nInviterId)

	return nErrorCode;
end

-- 客户端修改昵称协议
function UserInfoProtocol:ClientUpdateNickName(strNickName)
	
	LOG_DEBUG("UserInfoProtocol:ClientUpdateNickName:" .. strNickName)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsString(strNickName) then
		LOG_WARN("UserInfoProtocol:ClientUpdateInviterId strNickName is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_UserInfoLogic:UpdateNickName(objUser, strNickName)

	return nErrorCode;
end

-- 客户端绑定协议
function UserInfoProtocol:ClientBindingPhoneNo(strPhoneNo)
	
	LOG_DEBUG("UserInfoProtocol:ClientBindingPhoneNo:" .. strPhoneNo)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsString(strPhoneNo) then
		LOG_WARN("UserInfoProtocol:ClientUpdateInviterId strPhoneNo is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_UserInfoLogic:BindingPhoneNo(objUser, strPhoneNo)

	return nErrorCode;
end

G_UserInfoProtocol = UserInfoProtocol:new()