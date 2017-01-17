
function OnClientRequest(nHandlerId, nEventId, nSequenceId, strJson)
	local bRet = xpcall(function() ClientRequest(nHandlerId, nEventId, nSequenceId, strJson) end, __TRACKBACK__);
	local nRetCode = -1;
	if bRet then
		nRetCode = 0;
	end
	return nRetCode;
end

function ClientRequest(nHandlerId, nEventId, nSequenceId, strJson)
	
	LOG_INFO("RECEIVE:" .. strJson)

	if not IsNumber(nHandlerId) then
		LOG_ERROR("nHandlerId is not number");
		return 0;
	end

	if not IsNumber(nEventId) then
		LOG_ERROR("nEventId is not number");
		return 0;
	end

	if not IsNumber(nSequenceId) then
		LOG_ERROR("nSequenceId is not number");
		return 0;
	end

	local tbParam = json.decode(strJson);

	-- 添加到请求队列里
	G_NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam)

	if nEventId == EVENT_ID.SYSTEM.LOGIN_DIRECT then
		LOG_INFO("OnClientLoginDirect..........1")
		return OnClientLoginDirect(nHandlerId, nEventId, nSequenceId, tbParam);
	end

	return 0;
end

-- 直接登录
function OnClientLoginDirect(nHandlerId, nEventId, nSequenceId, tbParam)
	local nErrorCode = G_UserManager:CheckRegisterInfo(tbParam);
	if IsOkCode(nErrorCode) then
		LOG_INFO("OnClientLoginDirect..........2")
		-- 把nHandlerId当作nUserId来用，在OnRedisResponse使用时注意
		G_RegisterRedis:GetValue(nHandlerId, EVENT_ID.SYSTEM.GET_DEVICE_ID, tbParam.device_id);
	else
		-- 参数有误，直接返回给客户端
		G_NetManager:PopRequestFromSquence(nHandlerId);
		G_NetManager:SendToGateway(nSequenceId, nEventId, nErrorCode, nHandlerId, 0, "");
	end
end

-- 注册函数
function OnClientRegister(nHandlerId, nEventId, nSequenceId, tbParam)

	LOG_INFO("Call OnClientRegister...");
	local nErrorCode, nUserId = G_UserManager:Register(nHandlerId, tbParam);

	if nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_INFO("OnClientRegister PARAMTER_ERROR")
		LOG_INFO("OnClientLoginDirect..........4")
		G_NetManager:SendToGateway(nSequenceId, EVENT_ID.SYSTEM.LOGIN_DIRECT, nErrorCode, nHandlerId, 0, "");
	end
end

-- 登录函数
function OnClientLogin(nHandlerId, tbParam)

	local nErrorCode = G_UserManager:CheckUserInfo(nHandlerId, tbParam);
	if nErrorCode == ERROR_CODE.SYSTEM.USER_DATA_NIL then
		LOG_INFO("OnClientLogin User Info does not cache...")
		local nUserId = tbParam.user_id
		return G_GameDataRedis:GetValue(nUserId, EVENT_ID.SYSTEM.GET_GAME_DATA, nUserId);
	elseif nErrorCode == ERROR_CODE.SYSTEM.PARAMTER_ERROR then
		LOG_INFO("OnClientLogin paramter error...")
	elseif IsOkCode(nErrorCode) then
		LOG_INFO("OnClientLogin ok...")
		local nUserId = tbParam.user_id
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
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
		LOG_INFO("response data is nil");
	end

	LOG_INFO("LUA Redis Response：".."nEventId:" .. nEventId .. ", strRepsonseJson:" .. strRepsonseJson);
	if nEventId == EVENT_ID.SYSTEM.GET_DEVICE_ID then
		
		local nHandlerId = nUserId;
		local nSequenceId = G_NetManager:GetSquenceIdFromSquence(nHandlerId);
		local tbParam = G_NetManager:GetParamFromSquence(nHandlerId);

		LOG_INFO("ON GET DEVICE ID BACK..........3")

		-- 还没注册
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) <= 0 then
			LOG_INFO("Go to Register");
			LOG_INFO("nHandlerId Id:" .. nHandlerId);
			LOG_INFO("Squence Id:" .. nSequenceId);
			return OnClientRegister(nHandlerId, EVENT_ID.SYSTEM.REGISTERING, nSequenceId, tbParam)
		end

		local nUserId = tonumber(strRepsonseJson);
		local tbLoginParam = {}
		tbLoginParam.user_id = nUserId;
		return OnClientLogin(nHandlerId, tbLoginParam);
	end

	if nEventId == EVENT_ID.SYSTEM.REGISTERING then
		LOG_INFO("ON REGISTERING BACK..........4")
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end

	if nEventId == EVENT_ID.SYSTEM.GET_GAME_DATA then
		LOG_INFO("ON GET GAME DATA BACK..........5")
		local tbGameData = json.decode(strRepsonseJson)
		LOG_TABLE(tbGameData)
		G_UserManager:CacheUserGameData(nUserId, tbGameData)
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);
		OnResponeClientLogin(nUserId, nErrorCode, nRetInfo)
	end

end







