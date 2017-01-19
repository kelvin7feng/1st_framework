
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbContent)

	local tbParam = tbContent.parameter

	if not IsTable(tbParam) then
		LOG_ERROR("parameter of request is nil...")
		return;
	end
	
	if nEventId == EVENT_ID.CLIENT_LOGIN.LOGIN_DIRECT then
		LOG_DEBUG("OnClientLoginDirect..........1")
		return OnClientLoginDirect(nHandlerId, nEventId, nSequenceId, tbParam);
	end

	return 0;
end

-- 直接登录
function OnClientLoginDirect(nHandlerId, nEventId, nSequenceId, tbParam)
	local nErrorCode = G_UserManager:CheckRegisterInfo(tbParam);
	if IsOkCode(nErrorCode) then
		LOG_DEBUG("OnClientLoginDirect..........2")
		-- 把nHandlerId当作nUserId来用，在OnRedisResponse使用时注意
		G_RegisterRedis:GetValue(nHandlerId, EVENT_ID.GET_ASYN_DATA.GET_DEVICE_ID, tbParam.device_id);
	else
		-- 参数有误，直接返回给客户端
		G_NetManager:PopRequestFromSquence(nHandlerId);
		G_NetManager:SendToGateway(nSequenceId, nEventId, nErrorCode, nHandlerId, 0, "");
	end
end

-- 注册函数
function OnClientRegister(nHandlerId, nEventId, nSequenceId, tbParam)

	LOG_DEBUG("Call OnClientRegister...");
	local nErrorCode, nUserId = G_UserManager:Register(nHandlerId, tbParam);

	if nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_DEBUG("OnClientRegister PARAMTER_ERROR")
		LOG_DEBUG("OnClientLoginDirect..........4")
		G_NetManager:SendToGateway(nSequenceId, EVENT_ID.CLIENT_LOGIN.LOGIN_DIRECT, nErrorCode, nHandlerId, 0, "");
	end
end

-- 登录函数
function OnClientLogin(nHandlerId, tbParam)

	local nErrorCode = G_UserManager:CheckUserInfo(nHandlerId, tbParam);
	if nErrorCode == ERROR_CODE.SYSTEM.USER_DATA_NIL then
		LOG_DEBUG("OnClientLogin User Info does not cache...")
		local nUserId = tbParam.user_id
		return G_GameDataRedis:GetValue(nUserId, EVENT_ID.GET_ASYN_DATA.GET_GAME_DATA, nUserId);
	elseif nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_DEBUG("OnClientLogin paramter error...")
	elseif IsOkCode(nErrorCode) then
		LOG_DEBUG("OnClientLogin ok...")
		local nUserId = tbParam.user_id
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end

end

-- 响应客户端登录请求
function OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
	G_NetManager:SendToGateway(nSequenceId, EVENT_ID.CLIENT_LOGIN.LOGIN_DIRECT, nErrorCode, nHandlerId, string.len(json.encode(nRetInfo)), nRetInfo);
end

-- 响应redis
function OnRedisRespone(nUserId, nEventId, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_DEBUG("response data is nil");
	end

	LOG_DEBUG("LUA Redis Response：".."nEventId:" .. nEventId .. ", strRepsonseJson:" .. strRepsonseJson);
	OnResponseGlobalConfigEvent(nEventId, strRepsonseJson);
	OnResponseLoginEvent(nUserId, nEventId, strRepsonseJson);

end

-- 登录流程事件
function OnResponseLoginEvent(nUserId, nEventId, strRepsonseJson)
	
	if nEventId == EVENT_ID.GET_ASYN_DATA.GET_DEVICE_ID then
		
		local nHandlerId = nUserId;
		local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
		local tbParam = G_NetManager:GetParamFromSquence(nHandlerId);

		-- 还没注册
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) <= 0 then
			LOG_DEBUG("Go to Register");
			LOG_DEBUG("nHandlerId Id:" .. nHandlerId);
			LOG_DEBUG("Squence Id:" .. nSequenceId);
			return OnClientRegister(nHandlerId, EVENT_ID.GET_ASYN_DATA.REGISTERING, nSequenceId, tbParam)
		end

		local nUserId = tonumber(strRepsonseJson);
		local tbLoginParam = {}
		tbLoginParam.user_id = nUserId;
		return OnClientLogin(nHandlerId, tbLoginParam);
	end

	if nEventId == EVENT_ID.GET_ASYN_DATA.REGISTERING then
		LOG_DEBUG("ON REGISTERING BACK..........4")
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end

	if nEventId == EVENT_ID.GET_ASYN_DATA.GET_GAME_DATA then
		LOG_DEBUG("ON GET GAME DATA BACK..........5")
		local tbGameData = json.decode(strRepsonseJson)
		G_UserManager:CacheUserObject(nUserId, tbGameData)
		LOG_DEBUG(tbGameData);
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end
end
