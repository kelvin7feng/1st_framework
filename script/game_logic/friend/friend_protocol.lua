FriendProtocol = class()

function FriendProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.GET_FRIEND_LIST, self.ClientGetFriendList, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.GET_ADD_FRIEND_REQUEST, self.ClientGetAddFriendRequest, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.ADD_FRIEND, self.ClientAddFriend, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.PASS_REQUEST, self.ClientPassRequest, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.SEARCH_USER, self.ClientSearchUser, self);
	G_EventManager:Register(EVENT_ID.CLIENT_FRIEND.CHAT, self.ClientChat, self);
end

-- 客户端搜索用户
function FriendProtocol:ClientChat(nUserId, strContent)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	if not IsString(strContent) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end	

	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:Chat(objUser, nUserId, strContent);
end

-- 客户端搜索用户
function FriendProtocol:ClientSearchUser(nUserId)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nUserId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:SearchUser(objUser, nUserId);
end

-- 客户端增加好友列表协议
function FriendProtocol:ClientGetAddFriendRequest()
	
	LOG_DEBUG("FriendProtocol:ClientGetAddFriendRequest")
	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:GetAddFriendRequest(objUser);
end

-- 客户端增加好友协议
function FriendProtocol:ClientGetFriendList()
	
	LOG_DEBUG("FriendProtocol:ClientGetFriendList")
	local objUser = G_UserManager:GetCurrentUserObject();
	return G_FriendLogic:GetFriendList(objUser);
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