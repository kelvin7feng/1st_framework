GameProtocol = class()

function GameProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_ENTER_GAME.ENTER_ROOM, self.ClientEnterRoom, self);
end

-- 客户端进入游戏房间
function GameProtocol:ClientEnterRoom(nGameType, nRoomId)
	
	LOG_DEBUG("GameProtocol:ClientEnterRoom")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nGameType) then
		LOG_WARN("GameProtocol:ClientEnterRoom nGameType is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	if not IsNumber(nRoomId) then
		LOG_WARN("GameProtocol:ClientEnterRoom nRoomId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();
	return G_GameManager:EnterGame(objUser, nGameType, nRoomId);
end

G_GameProtocol = GameProtocol:new()