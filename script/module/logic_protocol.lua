
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	if not IsTable(tbParam) then
		LOG_ERROR("parameter of request is nil...")
		return 0;
	end

	if nEventId == EVENT_ID.CLIENT_LOGIN.ENTER_GAME then
		LOG_DEBUG("OnClientEnterGame..........1")
		return OnClientEnterGame(nHandlerId, nEventId, nSequenceId, tbParam)
	end

	local nUserId = G_NetManager:GetUserId(nHandlerId);
	if not nUserId then
		return 0;
	end

	G_UserManager:SetCurrentUserObject(nUserId);
	
	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);
	if nErrorCode ~= ERROR_CODE.NET.LOGIN_TO_ROOM_SERVER then
		G_NetManager:SendToGateway(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
	else
		G_NetManager:SendToCenter(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);
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

	--[[local nUserId = G_NetManager:GetUserId(nHandlerId);
	if not nUserId then
		return 0;
	end]]--

	--G_UserManager:SetCurrentUserObject(nUserId);
	
	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);

	G_NetManager:PopRequestFromSquence(nHandlerId);
	--G_UserManager:Commit();

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
	OnResponseFriendEvent(nUserId, nEventId, strRepsonseJson);
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

-- 响应增加好友事件, nUserId: 发送请求玩家id, strRepsonseJson: 接收请求的玩家数据
function OnResponseFriendEvent(nUserId, nEventId, strRepsonseJson)
	if nEventId == EVENT_ID.GET_ASYN_DATA.ADD_FRIEND_GET_GAME_DATA then
		LOG_DEBUG("ON GET GAME DATA BACK..........1")
		LOG_DEBUG("|" .. strRepsonseJson .. "|")
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
			local tbGameData = json.decode(strRepsonseJson)
			local objInvitee = UserData:new(tbGameData);
			G_FriendLogic:AddFriendRequest(nUserId, objInvitee);
		else
			LOG_ERROR("User Is Nil");
		end
	end
end
