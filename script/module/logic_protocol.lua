
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	if nEventId == EVENT_ID.CLIENT_LOGIN.ENTER_GAME then
		LOG_DEBUG("OnClientEnterHall..........1")
		return OnClientEnterHall(nHandlerId, nEventId, nSequenceId, tbParam)
	end

	if nEventId == EVENT_ID.GATEWAY_EVENT.USER_DISCONNECT then
		G_EventManager:DispatcherEvent(nEventId, tbParam);
		return 0;
	end

	local nUserId = G_NetManager:GetUserId(nHandlerId);
	if not nUserId then
		return false;
	end

	G_UserManager:SetCurrentUserObject(nUserId);
	G_NetManager:SetCurrentHandlerId(nHandlerId);
	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);
	if nErrorCode ~= ERROR_CODE.SYSTEM.ASYN_EVENT then

		-- 映射事件源
		if ASYNC_EVENT_MAP_TO_SOURCE_EVENT[nEventId] then
			nEventId = ASYNC_EVENT_MAP_TO_SOURCE_EVENT[nEventId];
		end

		if nErrorCode == ERROR_CODE.NET.LOGIC_TO_ROOM_SERVER then
			G_NetManager:SendToRoomServerFromLogic(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
		else
			G_NetManager:SendToGateway(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
		end
	end

	G_UserManager:Commit();

	return 0;
end

-- 进入游戏，获取玩家信息
function OnClientEnterHall(nHandlerId, nEventId, nSequenceId, tbParam)
	local nUserId = tbParam[1];

	-- 更新句柄和玩家Id
	G_NetManager:UpdateHandlerIdAndUserId(nUserId, nHandlerId);

	local nErrorCode = G_UserManager:CheckUserDataStatus(nHandlerId, nUserId);
	if nErrorCode == ERROR_CODE.SYSTEM.USER_DATA_NIL then
		LOG_DEBUG("OnClientEnterHall User Info does not cache...")
		return G_GameDataRedis:GetValue(nUserId, EVENT_ID.GET_ASYN_DATA.LOGIC_GET_GAME_DATA, nUserId);
	elseif nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_DEBUG("OnClientEnterHall paramter error...")
	elseif IsOkCode(nErrorCode) then
		LOG_DEBUG("OnClientEnterHall ok...")
		local nErrorCode,objUser = G_UserManager:EnterGame(nUserId);
		local tbRetInfo = objUser:GetGameData();
		OnResponeClientEnterHall(nUserId, nErrorCode, {tbRetInfo});
	end
end

-- 响应客户端登录请求
function OnResponeClientEnterHall(nUserId, nErrorCode, tbRetInfo)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);

	table.insert(tbRetInfo,G_ConfigManager:GetGameList())
	G_NetManager:SendToGateway(nSequenceId, EVENT_ID.CLIENT_LOGIN.ENTER_GAME, nErrorCode, nHandlerId, tbRetInfo);
end

-- 处理数据库回调
function OnRedisCallback(nUserId, nEventId, tbParam)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	if not nHandlerId then
		return 0;
	end
	
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);

	--LOG_DEBUG("nHandlerId :" .. nHandlerId)
	--LOG_DEBUG("nSequenceId :" .. nSequenceId)

	local bRet = xpcall(
		function()
			return ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam);
		end, __TRACKBACK__);

	if not bRet then
		LOG_ERROR("OnRedisMulDataRespone Failed...");
	end
end

-- 响应redis
function OnRedisRespone(nAsyncSquenceId, nUserId, nEventId, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_DEBUG("response data is nil");
	end

	local tbParam = G_AsyncManager:Pop(nAsyncSquenceId);

	if nEventId == EVENT_ID.GLOBAL_CONFIG.GET_USER_GLOBAL_ID then
		OnResponseGlobalConfigEvent(nEventId, strRepsonseJson);
	elseif nEventId == EVENT_ID.GET_ASYN_DATA.LOGIC_GET_GAME_DATA then
		OnResponseEnterHallEvent(nUserId, nEventId, strRepsonseJson);
	else
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
			local tbRetData = strRepsonseJson;
			local strTableName = G_AsyncManager:GetSquenceIdToTableName(nAsyncSquenceId);
			if IsString(strTableName) and strTableName == DATABASE_TABLE_NAME.GAME_DATA then
				local tbGameData = json.decode(strRepsonseJson);
				tbRetData = UserData:new(tbGameData);
			end

			if tbParam and tbRetData then
				table.insert(tbParam, tbRetData);
			end
		end

		OnRedisCallback(nUserId, nEventId, tbParam);
		G_AsyncManager:SetSquenceIdToTableNameNil(nAsyncSquenceId);
	end
end

-- 响应多个数据redis, 只支持处理一次异步, 如果是多个异步, 需要单独处理
function OnRedisMulDataRespone(nAsyncSquenceId, nUserId, nEventId, tbMulData)
	
	local tbParam = G_AsyncManager:Pop(nAsyncSquenceId);
	local nHandlerId = nil;
	local nSequenceId = nil;
	table.insert(tbParam, tbMulData);

	OnRedisCallback(nUserId, nEventId, tbParam);
	G_AsyncManager:SetSquenceIdToTableNameNil(nAsyncSquenceId);
end

-- 响应进入游戏事件
function OnResponseEnterHallEvent(nUserId, nEventId, strRepsonseJson)
	if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
		local tbGameData = json.decode(strRepsonseJson)
		G_UserManager:CacheUserObject(tbGameData)
		G_UserManager:SetCurrentUserObject(nUserId);
		local nErrorCode, objUser = G_UserManager:EnterGame(nUserId);
		local tbRetInfo = objUser:GetGameData();
		OnResponeClientEnterHall(nUserId, nErrorCode, {tbRetInfo})
	else
		LOG_DEBUG("User Is Nil");
		OnResponeClientEnterHall(nUserId, ERROR_CODE.SYSTEM.USER_DATA_NIL, "")
	end
end
