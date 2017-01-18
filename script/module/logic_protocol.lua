
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)
	
	if nEventId == EVENT_ID.SYSTEM.ENTER_GAME then
		LOG_DEBUG("OnClientEnterGame..........1")
		OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	end

	return 0;
end

-- 进入游戏，获取玩家信息
function OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	local nErrorCode = G_UserManager:CheckUserInfo(nHandlerId, tbParam);
	if nErrorCode == ERROR_CODE.SYSTEM.USER_DATA_NIL then
		LOG_DEBUG("OnClientEnterGame User Info does not cache...")
		local nUserId = tbParam.user_id
		return G_GameDataRedis:GetValue(nUserId, EVENT_ID.SYSTEM.LOGIC_GET_GAME_DATA, nUserId);
	elseif nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_DEBUG("OnClientEnterGame paramter error...")
	elseif IsOkCode(nErrorCode) then
		LOG_DEBUG("OnClientEnterGame ok...")
		local nUserId = tbParam.user_id
		local nErrorCode, nRetInfo = G_UserManager:EnterGame(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end
end

-- 响应客户端登录请求
function OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
	G_NetManager:SendToGateway(nSequenceId, EVENT_ID.SYSTEM.LOGIN_DIRECT, nErrorCode, nHandlerId, string.len(json.encode(nRetInfo)), nRetInfo);
end

-- 响应redis
function OnRedisRespone(nUserId, nEventId, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_DEBUG("response data is nil");
	end

	OnResponseGlobalConfigEvent(nEventId, strRepsonseJson);
	OnResponseEnterGameEvent(nUserId, nEventId, strRepsonseJson);
end

-- 响应进入游戏事件
function OnResponseEnterGameEvent(nUserId, nEventId, strRepsonseJson)
	if nEventId == EVENT_ID.SYSTEM.LOGIC_GET_GAME_DATA then
		LOG_DEBUG("ON GET GAME DATA BACK..........1")
		local tbGameData = json.decode(strRepsonseJson)
		LOG_TABLE(tbGameData)
		G_UserManager:CacheUserGameData(nUserId, tbGameData)
		local nErrorCode, nRetInfo = G_UserManager:EnterGame(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end
end
