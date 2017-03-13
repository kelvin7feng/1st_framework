
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	if nEventId == EVENT_ID.CLIENT_LOGIN.ENTER_GAME then
		LOG_DEBUG("OnClientEnterGame..........1")
		return OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	end

	local nUserId = G_NetManager:GetUserId(nHandlerId);
	if not nUserId then
		return false;
	end

	G_UserManager:SetCurrentUserObject(nUserId);
	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);
	if nErrorCode ~= ERROR_CODE.SYSTEM.ASYN_EVENT then
		if nEventId == EVENT_ID.GET_ASYN_DATA.ADD_FRIEND_GET_GAME_DATA then
			nEventId = EVENT_ID.CLIENT_FRIEND.ADD_FRIEND;
		elseif nEventId == EVENT_ID.GET_ASYN_DATA.GET_FRIEND_LIST then
			nEventId = EVENT_ID.CLIENT_FRIEND.GET_FRIEND_LIST;
		elseif nEventId == EVENT_ID.GET_ASYN_DATA.GET_ADD_FRIEND_REQUEST then
			nEventId = EVENT_ID.CLIENT_FRIEND.GET_ADD_FRIEND_REQUEST;
		elseif nEventId == EVENT_ID.GET_ASYN_DATA.SEARCH_USER_DATA then
			nEventId = EVENT_ID.CLIENT_FRIEND.SEARCH_USER;
		end

		if nErrorCode ~= ERROR_CODE.NET.LOGIN_TO_ROOM_SERVER then
			G_NetManager:SendToGateway(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
		else
			G_NetManager:SendToCenter(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
		end
	end

	G_UserManager:Commit();

	return 0;
end

function CenterRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	LOG_DEBUG("CenterRequest...")
	LOG_DEBUG("nHandlerId:" .. nHandlerId);
	if not IsTable(tbParam) then
		LOG_ERROR("parameter of request is nil...")
		return 0;
	end
	
	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);

	G_NetManager:PopRequestFromSquence(nHandlerId);

	return 0;
end

-- 进入游戏，获取玩家信息
function OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	local nUserId = tbParam[1]
	local nErrorCode = G_UserManager:CheckUserDataStatus(nHandlerId, nUserId);
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
function OnResponeClientEnterGame(nUserId, nErrorCode, tbRetInfo)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
	G_NetManager:SendToGateway(nSequenceId, EVENT_ID.CLIENT_LOGIN.ENTER_GAME, nErrorCode, nHandlerId, tbRetInfo);
end

-- 响应redis
function OnRedisRespone(nUserId, nEventId, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_DEBUG("response data is nil");
	end

	LOG_DEBUG("|" .. strRepsonseJson .. "|")
	OnResponseGlobalConfigEvent(nEventId, strRepsonseJson);
	OnResponseEnterGameEvent(nUserId, nEventId, strRepsonseJson);
end

-- 响应多个数据redis, 只支持处理一次异步, 如果是多个异步, 需要单独处理
function OnRedisMulDataRespone(nAsyncSquenceId, nUserId, nEventId, tbMulData)
	LOG_DEBUG("nAsyncSquenceId :" .. nAsyncSquenceId)
	LOG_DEBUG("nUserId :" .. nUserId)
	LOG_DEBUG("nEventId :" .. nEventId)
	LOG_DEBUG("tbMulData type:" .. type(tbMulData))
	LOG_DEBUG("tbMulData :" .. json.encode(tbMulData))
	
	local tbParam = G_AsyncManager:Pop(nAsyncSquenceId);
	local nHandlerId = nil;
	local nSequenceId = nil;
	if nEventId == EVENT_ID.GET_ASYN_DATA.ADD_FRIEND_GET_GAME_DATA then
		local tbGameData = json.decode(table.remove(tbMulData, 1));
		local objInvitee = UserData:new(tbGameData);
		table.insert(tbParam, objInvitee);

	elseif nEventId == EVENT_ID.GET_ASYN_DATA.GET_FRIEND_INVITER_DATA then
		local tbGameData = json.decode(table.remove(tbMulData, 1));
		local objInviter = UserData:new(tbGameData);
		table.insert(tbParam, objInviter);

	elseif nEventId == EVENT_ID.GET_ASYN_DATA.SEARCH_USER_DATA then
		local tbGameData = json.decode(table.remove(tbMulData, 1));
		local objUser = UserData:new(tbGameData);
		table.insert(tbParam, objUser);
		
	else
		table.insert(tbParam, tbMulData);
		
	end

	nHandlerId = G_NetManager:GetHandlerId(nUserId);
	nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
	LOG_DEBUG("nHandlerId :" .. nHandlerId)
	LOG_DEBUG("nSequenceId :" .. nSequenceId)

	local bRet = xpcall(
		function()
			return ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam);
		end, __TRACKBACK__);

	if not bRet then
		LOG_ERROR("OnRedisMulDataRespone Failed...");
	end
end

-- 响应进入游戏事件
function OnResponseEnterGameEvent(nUserId, nEventId, strRepsonseJson)
	if nEventId == EVENT_ID.GET_ASYN_DATA.LOGIC_GET_GAME_DATA then
		LOG_DEBUG("ON GET GAME DATA BACK..........1")
		LOG_DEBUG("|" .. strRepsonseJson .. "|")
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
			local tbGameData = json.decode(strRepsonseJson)
			G_UserManager:CacheUserObject(tbGameData)
			local nErrorCode, objUser = G_UserManager:EnterGame(nUserId);
			local tbRetInfo = objUser:GetGameData();
			OnResponeClientEnterGame(nUserId, nErrorCode, {tbRetInfo})
		else
			LOG_DEBUG("User Is Nil");
			OnResponeClientEnterGame(nUserId, ERROR_CODE.SYSTEM.USER_DATA_NIL, "")
		end
	end
end
