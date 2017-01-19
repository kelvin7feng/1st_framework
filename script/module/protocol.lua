
-- 逻辑调用入口
function OnClientRequest(nHandlerId, nEventId, nSequenceId, strJson)
	local bRet = xpcall(
		function()
			LOG_DEBUG("RECEIVE:" .. strJson)

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

			local tbParam = json.decode(v);
			
			-- 添加到请求队列里
			G_NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam);

			ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam) 
		end, __TRACKBACK__);

	local nRetCode = -1;
	if bRet then
		nRetCode = 0;
	end
	
	return nRetCode;
end

-- 全局配置表事件
function OnResponseGlobalConfigEvent(nEventId, strRepsonseJson)
	if nEventId == EVENT_ID.GLOBAL_CONFIG.GET_USER_GLOBAL_ID then
		local bOnlyCache = false;
		if IsString(strRepsonseJson) and string.len(strRepsonseJson) > 0 then
			bOnlyCache = true;
		end

		G_GlobalConfigManager:SetUserGlobalId(strRepsonseJson, bOnlyCache);
	end
end