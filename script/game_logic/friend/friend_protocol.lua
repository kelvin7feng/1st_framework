FriendProtocol = class()

function FriendProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.ADD_FRIEND, self.ClientAddFriend, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.PASS_REQUEST, self.ClientPassRequest, self);
end

-- 客户端增加好友协议
function FriendProtocol:ClientAddFriend(nUserId)
	
	LOG_DEBUG("FriendProtocol:ClientAddFriend")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		LOG_WARN("FriendProtocol:ClientAddFriend nUserId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:AddFriend(objUser, nUserId);
end

-- 客户端通过好友协议
function FriendProtocol:ClientPassRequest(nInviter)
	
	LOG_DEBUG("FriendProtocol:ClientPassRequest")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nInviter) then
		LOG_WARN("FriendProtocol:ClientPassRequest nInviter is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:PassRequest(objUser, nInviter);
end

G_FriendProtocol = FriendProtocol:new()