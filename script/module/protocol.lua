
function OnClientRequest(nEventType, nHandlerId, strJson)
	
	LOG_INFO("nEventType:" .. nEventType)
	LOG_INFO("nHandlerId:" .. nHandlerId)
	LOG_INFO("RECEIVE:" .. strJson)
	if not IsNumber(nEventType) then
		LOG_ERROR("event type is not number");
		return 0;
	end

	local tbParam = json.decode(strJson);
	if nEventType == EVENT_TYPE.SYSTEM.REGISTER then
		local nErrorCode, nUserId = G_UserManager:Register(nHandlerId, tbParam);
		local tbUserInfo = "";
		if nUserId then
			tbUserInfo = json.encode(G_UserManager:GetUser(nUserId));
		end

		LOG_INFO("CALL REGISTER");
		LOG_INFO("nEventType:" .. nEventType);
		LOG_INFO("nErrorCode:" .. nErrorCode);
		LOG_INFO("tbUserInfo:" .. tbUserInfo);
		LOG_INFO("nHandlerId:" .. G_NetInfoManager:GetHandlerId(nUserId));
		CNet.SendToGameway(nEventType, nErrorCode, nHandlerId, string.len(tbUserInfo), tbUserInfo);

	end
	
    return 0;
end

function OnRedisRespone(nUserId, nEventType, strRepsonseJson)
	if not IsString(strRepsonseJson) then
		LOG_INFO("response data is nil");
	end

	LOG_INFO("LUA Redis Response");
	LOG_INFO("nUserId:" .. nUserId);
	LOG_INFO("nHandlerId:" .. G_NetInfoManager:GetHandlerId(nUserId));
	LOG_INFO("nEventType:" .. nEventType);
	LOG_INFO("strRepsonseJson:" .. strRepsonseJson);

	if nEventType == EVENT_TYPE.SYSTEM.REGISTER then
		LOG_INFO("register call back...");
	end
end