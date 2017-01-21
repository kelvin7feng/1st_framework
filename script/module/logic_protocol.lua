-- 全局唯一对象

function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	if not IsTable(tbParam) then
		LOG_ERROR("parameter of request is nil...")
		return;
	end

	if nEventId == EVENT_ID.CLIENT_LOGIN.ENTER_GAME then
		LOG_DEBUG("OnClientEnterGame..........1")
		return OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	end


	return 0;
end

-- 进入游戏，获取玩家信息
function OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	local nUserId = tbParam[1]
	local nErrorCode = G_UserManager:CheckUserInfo(nHandlerId, nUserId);
	if nErrorCode == ERROR_CODE.SYSTEM.USER_DATA_NIL then
		LOG_DEBUG("OnClientEnterGame User Info does not cache...")
		return G_GameDataRedis:GetValue(nUserId, EVENT_ID.GET_ASYN_DATA.LOGIC_GET_GAME_DATA, nUserId);
	elseif nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_DEBUG("OnClientEnterGame paramter error...")
	elseif IsOkCode(nErrorCode) then
		LOG_DEBUG("OnClientEnterGame ok...")
		local nErrorCode,objUser = G_UserManager:EnterGame(nUserId);
		local tbRetInfo = objUser:GetGameData();
		OnResponeClientEnterGame(nUserId, nErrorCode, {tbRetInfo});
	end
end

-- 响应客户端登录请求
function OnResponeClientEnterGame(nUserId, nErrorCode, nRetInfo)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
	G_NetManager:SendToGateway(nSequenceId, EVENT_ID.CLIENT_LOGIN.ENTER_GAME, nErrorCode, nHandlerId, string.len(json.encode(nRetInfo)), nRetInfo);
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
	if nEventId == EVENT_ID.GET_ASYN_DATA.LOGIC_GET_GAME_DATA then
		LOG_DEBUG("ON GET GAME DATA BACK..........1" .. strRepsonseJson)
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
			local tbGameData = json.decode(strRepsonseJson)
			G_UserManager:CacheUserObject(nUserId, tbGameData)
			local nErrorCode, objUser = G_UserManager:EnterGame(nUserId);
			local tbRetInfo = objUser:GetGameData();
			OnResponeClientEnterGame(nUserId, nErrorCode, {tbRetInfo})
		else
			LOG_DEBUG("User Is Nil");
			OnResponeClientEnterGame(nUserId, ERROR_CODE.SYSTEM.USER_DATA_NIL, "")
		end
	end
end
