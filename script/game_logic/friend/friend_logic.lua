FriendLogic = class()

function FriendLogic:ctor()
	G_EventManager:Register(EVENT_ID.GET_ASYN_DATA.GET_FRIEND_LIST, self.OnGetFriendList, self);
end

-- 获取好友请求列表
function FriendLogic:OnGetFriendList(tbFriendList)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;

	if not IsTable(tbFriendList) then
		LOG_ERROR("FriendLogic:OnGetFriendList tbFriendList is error...")
		return nErrorCode;
	end

	local tbClientFriendsData = {}
	for _,userData in pairs(tbFriendList) do
		if not IsTable(userData) then
			userData = json.decode(userData);
		end

		local tbFriendData = self:GetClientFriendData(userData);
		table.insert(tbClientFriendsData, tbFriendData);
        
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbClientFriendsData;
end

-- 抽取好友列表需要的数据
function FriendLogic:GetClientFriendData(tbUserInfo)
	
	local tbClientFriendData = nil;

	if tbUserInfo and tbUserInfo[GAME_DATA_TABLE_NAME.BASE_INFO] then
		local tbBaseInfo = tbUserInfo[GAME_DATA_TABLE_NAME.BASE_INFO]
		tbClientFriendData = {
			[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID] 				 = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID],
			[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR]					 = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR],
			[GAME_DATA_FIELD_NAME.BaseInfo.SEX]					     = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.SEX],
			[GAME_DATA_FIELD_NAME.BaseInfo.NAME]					 = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.NAME],
			[GAME_DATA_FIELD_NAME.BaseInfo.GOLD]				     = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.GOLD],
			[GAME_DATA_FIELD_NAME.BaseInfo.SIGNATURE]				 = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.SIGNATURE],
			[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR_URL]				 = tbBaseInfo[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR_URL],
		};
	end

	return tbClientFriendData;
end

-- 获取好友请求列表
function FriendLogic:GetAddFriendRequest(objUser)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("FriendLogic:AddFriend objUser is nil...")
		return nErrorCode;
	end

	local tbTempUser = nil;
	local tbFriendList = {};
	for i=1, 5 do
		tbTempUser = {
			[GAME_DATA_FIELD_NAME.BaseInfo.USER_ID] 				 = 100001 + i,
			[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR]					 = math.random(15),
			[GAME_DATA_FIELD_NAME.BaseInfo.SEX]					     = math.random(1),
			[GAME_DATA_FIELD_NAME.BaseInfo.NAME]					 = "Guest",
			[GAME_DATA_FIELD_NAME.BaseInfo.AVATAR_URL]				 = "",
		};
		table.insert(tbFriendList, tbTempUser);
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbFriendList;
end

-- 获取好友列表
function FriendLogic:GetFriendList(objUser)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local tbFriendList = objUser:GetFriendList();
	local nCount = CountTab(tbFriendList);
	LOG_DEBUG("GetFriendList nCount:" .. nCount)
	if nCount > 0 then
		nErrorCode = ERROR_CODE.SYSTEM.ASYN_EVENT;
		local tbTempList = {}
		for strUserId, _ in pairs(tbFriendList) do
			table.insert(tbTempList, strUserId);
		end

		LOG_DEBUG("FriendLogic:GetFriendList ............ " .. json.encode(tbTempList))
		G_GameDataRedis:MGetValue(objUser:GetUserId(), EVENT_ID.GET_ASYN_DATA.GET_FRIEND_LIST, tbTempList);
	else
		nErrorCode = ERROR_CODE.SYSTEM.OK;
	end
	
	return nErrorCode, tbFriendList or {};
end

-- 通过请求
function FriendLogic:PassRequest(objUser, nInviter)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("FriendLogic:AddFriend objUser is nil...")
		return nErrorCode;
	end

	-- 检查玩家ID是否合法
	local bIsOk = G_UserInfoLogic:CheckUserIdLegal(nInviter);
	if not bIsOk then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	bIsOk = self:IsFriendRequestExist(objUser, nInviter);
	if not bIsOk then
		LOG_WARN("FriendLogic:PassRequest Friend Request does not exist...")
		nErrorCode = ERROR_CODE.FRIEND.INVITER_REQUEST_IS_NULL;
		return nErrorCode;
	end

	-- 删除请求
	objUser:DelFriendRequest(nInviter);
	-- 增加好友
	objUser:AddToFriendList(nInviter);

	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 检查是否存在好友请求
function FriendLogic:IsFriendRequestExist(objUser, nInviter)
	local bIsOk = false;
	if not IsNumber(nInviter) then
		return bIsOk;
	end

	local tbAllRequest = objUser:GetFriendRequest();
	LOG_TABLE(objUser)
	LOG_TABLE(tbAllRequest)
	if tbAllRequest[tostring(nInviter)] then
		bIsOk = true;
	end

	return bIsOk;
end

-- 添加好友
function FriendLogic:AddFriend(objUser, nUserId)
	LOG_DEBUG("FriendLogic:AddFriend")
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("FriendLogic:AddFriend objUser is nil...")
		return nErrorCode;
	end

	-- 检查玩家ID是否合法
	local bIsOk = G_UserInfoLogic:CheckUserIdLegal(nUserId);
	if not bIsOk then
		nErrorCode = ERROR_CODE.SYSTEM.USER_NO_REGISTER;
		return nErrorCode;
	end

	local nInviterUserId = objUser:GetUserId();
	local bIsCache = G_UserManager:IsUserObjectCache(nUserId);
	if not bIsCache then
		-- 假设已经发送请求,留待数据回来再处理
		LOG_DEBUG("AddFriend User Info does not cache...")
		G_GameDataRedis:GetValue(nInviterUserId, EVENT_ID.GET_ASYN_DATA.ADD_FRIEND_GET_GAME_DATA, nUserId);
		nErrorCode = ERROR_CODE.SYSTEM.OK;
		return nErrorCode;
	end

	local objInvitee = G_UserManager:GetUserObject(nUserId);
	return self:AddFriendRequest(nInviterUserId, objInvitee)
end

-- 增加好友请求, nInviterUserId:邀请者, objInvitee:被邀请者
function FriendLogic:AddFriendRequest(nInviterUserId, objInvitee)

	LOG_DEBUG("FriendLogic:AddFriendRequest")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nInviterUserId) then
		LOG_ERROR("FriendLogic:AddFriendRequest nInviterUserId is not number");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	if not objInvitee then
		LOG_ERROR("FriendLogic:AddFriendRequest objInvitee is null");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	objInvitee:AddFriendRequest(nInviterUserId);

	-- 异步数据, 需要手动保存
	G_UserManager:SaveUserData(objInvitee);
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

G_FriendLogic = FriendLogic:new()