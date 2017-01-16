
function OnClientRequest(nHandlerId, nEventType, nSequenceId, strJson)
	
	LOG_INFO("nHandlerId:" .. nHandlerId)
	LOG_INFO("nEventType:" .. nEventType)
	LOG_INFO("uSequenceId:" .. nSequenceId)
	LOG_INFO("RECEIVE:" .. strJson)

	if not IsNumber(nHandlerId) then
		LOG_ERROR("nHandlerId is not number");
		return 0;
	end

	if not IsNumber(nEventType) then
		LOG_ERROR("nEventType is not number");
		return 0;
	end

	if not IsNumber(nSequenceId) then
		LOG_ERROR("nSequenceId is not number");
		return 0;
	end

	-- 添加到请求队列里
	G_NetManager:PushRequestToSquence(nHandlerId, nSequenceId)

	local tbParam = json.decode(strJson);
	if nEventType == EVENT_TYPE.SYSTEM.REGISTER then
		return OnClientRegister(nHandlerId, nEventType, nSequenceId, tbParam);
	end

	if nEventType == EVENT_TYPE.SYSTEM.LOGIN then
		return OnClientLogin(nHandlerId, nEventType, nSequenceId, tbParam);			
	end
	
	local nErrorCode = ERROR_CODE.SYSTEM.OK;
	local tbTest = {};
	tbTest.msg = "event " .. nEventType .. " is null function...";
	tbTest = json.encode(tbTest);
	nSequenceId = G_NetManager:PopRequestFromSquence(nHandlerId);
	G_NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, string.len(tbTest), tbTest);
	--

	return 0;
    --return xpcall(function() G_UserManager:HelloDebug() end, __TRACKBACK__);
end

function OnClientRegister(nHandlerId, nEventType, nSequenceId, tbParam)
	local nErrorCode, nUserId = G_UserManager:Register(nHandlerId, tbParam);
	local tbUserInfo = nil;
	if nErrorCode == ERROR_CODE.SYSTEM.OK then
		tbUserInfo = json.encode(G_UserManager:GetUser(nUserId)) or "";
	end

	tbUserInfo = tbUserInfo or "";
	G_NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, string.len(tbUserInfo), tbUserInfo);
end

function OnClientLogin(nHandlerId, nEventType, nSequenceId, tbParam)
	G_UserManager:CheckUserInfo(nHandlerId, tbParam);
end

function OnRedisRespone(nUserId, nEventType, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_INFO("response data is nil");
	end

	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	LOG_INFO("LUA Redis Response");
	LOG_INFO("nUserId:" .. nUserId);
	LOG_INFO("nHandlerId:" .. nHandlerId);
	LOG_INFO("nEventType:" .. nEventType);
	LOG_INFO("strRepsonseJson:" .. strRepsonseJson);

	if nEventType == EVENT_TYPE.SYSTEM.REGISTER then
		LOG_INFO("register call back...");
	end

	if nEventType == EVENT_TYPE.SYSTEM.LOGIN then

		-- 缓存玩家数据到虚拟机里
		if strRepsonseJson then
			G_UserManager:CacheUser(nUserId, strRepsonseJson)
		end

		local nSequenceId = G_NetManager:PopRequestFromSquence(nHandlerId);
		local nErrorCode, nRetInfo = G_UserManager:Login(nUserId);

		LOG_INFO("get user info call back...");
		LOG_INFO("nErrorCode:" .. nErrorCode);
		LOG_INFO("nSequenceId:" .. nSequenceId);
		
		G_NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, string.len(json.encode(nRetInfo)), nRetInfo);
	end
end







