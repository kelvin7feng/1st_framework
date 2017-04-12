GameManager = class()

function GameManager:ctor()
	
	self.m_tbUserInGame = {}
end

function GameManager:SetUserInGame(nUserId)

end

function GameManager:IsUserInGame(nUserId)

end

-- 进入游戏
function GameManager:EnterGame(objUser, nGameType, nRoomId)
	
	local nErrorCode = self:CheckCondition(objUser, nGameType, nRoomId);
	if not IsOkCode(nErrorCode) then
		return nErrorCode;
	end

	local tbPacket = self:GetPacketOfRoomNeed(objUser, nGameType, nRoomId)
	return ERROR_CODE.NET.LOGIC_TO_ROOM_SERVER, unpack(tbPacket);
end

-- 获取房间服需要的信息
function GameManager:GetPacketOfRoomNeed(objUser, nGameType, nRoomId)
	local nHandlerId = G_NetManager:GetCurrentHandlerId();
	local tbRet = {objUser:GetGameData(), nHandlerId, nGameType, nRoomId};
	return tbRet;
end

-- 检查进入游戏的条件
function GameManager:CheckCondition(objUser, nGameType, nRoomId)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("GameManager:EnterGame objUser is nil...")
		return nErrorCode;
	end

	if not IsNumber(nGameType) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	if not IsNumber(nRoomId) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local bIsOpen = self:IsGameTypeOpen(nGameType);
	if not bIsOpen then
		nErrorCode = ERROR_CODE.CORE_GAME.GAME_TYPE_IS_CLOSE;
		return nErrorCode;
	end

	bIsOpen = self:IsGameRoomOpen(nRoomId);
	if not bIsOpen then
		nErrorCode = ERROR_CODE.CORE_GAME.GAME_ROOM_DOES_NOT_EXIST;
		return nErrorCode;
	end

	local nUserGold = objUser:GetGold();
	local bIsEnough = self:CheckGoldIsEnough(nUserGold, nGameType, nRoomId);
	if not bIsEnough then
		nErrorCode = ERROR_CODE.CORE_GAME.GOLD_IS_OUT_OF_RANGE;
		return nErrorCode;
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode;
end

-- 检查金币是否足够
function GameManager:CheckGoldIsEnough(nUserGold, nGameType, nRoomId)
	local tbConfig = G_ConfigManager:GetGameTypeConfig(nGameType);
	local nGameId = tbConfig[ConfigTableFieldName.GameType.ID];
	local nRoomConfig = G_ConfigManager:GetConfig(TableConfigName.GAME_LIST, nGameId, nRoomId);
	local nMin = nRoomConfig[ConfigTableFieldName.GameList.ENTER_MIN];
	local nMax = nRoomConfig[ConfigTableFieldName.GameList.ENTER_MAX];

	LOG_INFO("nMin:" .. nMin)
	LOG_INFO("nMax:" .. nMax)
	LOG_INFO("nGold:" .. nUserGold)
	local bIsEnough = false;
	if nUserGold >= nMin then
		if (nMax == -1) or (nUserGold < nMax) then
			bIsEnough = true;
		end
	end

	return bIsEnough;
end

-- 检查游戏类型是否开放
function GameManager:IsGameTypeOpen(nGameType)
	local bIsOpen = false;
	local tbConfig = G_ConfigManager:GetConfig(TableConfigName.GAME_TYPE);
	for _, tbTemp in pairs(tbConfig) do
		if tbTemp[ConfigTableFieldName.GameList.GAME_TYPE] then
			bIsOpen = true;
			break;
		end
	end

	return bIsOpen;
end

-- 检查游戏房间是否开放
function GameManager:IsGameRoomOpen(nRoomId)
	local bIsOpen = false;
	local tbConfig = G_ConfigManager:GetConfig(TableConfigName.GAME_LIST);
	for _, tbTemp in pairs(tbConfig) do
		if tbTemp[nRoomId] then
			bIsOpen = true;
			break;
		end
	end

	return bIsOpen;
end

G_GameManager = GameManager:new()