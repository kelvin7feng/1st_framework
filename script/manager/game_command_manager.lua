GameCommandManager = class()

function GameCommandManager:ctor()
	G_EventManager:Register(EVENT_ID.CLIENT_TEST.ADD_GOLD, self.AddGold, self)
	G_EventManager:Register(EVENT_ID.CLIENT_TEST.CLEAR_FRIEND, self.ClearFriend, self)
	G_EventManager:Register(EVENT_ID.CLIENT_TEST.RESET_USER_DATA, self.ResetUserData, self)
end

function GameCommandManager:ResetUserData()
	LOG_DEBUG("GameCommandManager:ResetUserData()")
	local objUser = G_UserManager:GetCurrentUserObject()
	local tbGameData = G_UserManager:GetInitGameData(objUser:GetUserId());
	objUser:Reset(tbGameData);

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, tbGameData
end

function GameCommandManager:ClearFriend()
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local objUser = G_UserManager:GetCurrentUserObject()
	
	local tbFriendAll = objUser:GetFriendList();
	for strUserId, _ in pairs(tbFriendAll) do
		objUser:DelFriend(tonumber(strUserId))
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode
end

function GameCommandManager:AddGold(nVal)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nVal) then
		LOG_DEBUG("nval is not number...");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode
	end
	local objUser = G_UserManager:GetCurrentUserObject()
	local nGold = objUser:GetGold();
	objUser:AddGold(nVal);

	local nNewGold = objUser:GetGold();
	LOG_DEBUG("nNewGold:" .. nNewGold);
	
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode, nNewGold
end

G_GameCommandManager = GameCommandManager:new()