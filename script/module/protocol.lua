
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

			local tbParam = json.decode(strJson);

			-- 添加到请求队列里
			G_NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam);

			ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

		end, __TRACKBACK__);

	-- 如果报错, 把请求从队列中移除
	if not bRet then
		G_NetManager:PopRequestFromSquence(nHandlerId);		
	end
	
	return tonumber(bRet);
end

-- 接收中心服请求逻辑调用入口
function OnCenterRequest(nHandlerId, nEventId, nSequenceId, strJson)
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

			local tbParam = json.decode(strJson);

			-- 添加到请求队列里
			G_NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam);

			CenterRequest(nHandlerId, nEventId, nSequenceId, tbParam)

		end, __TRACKBACK__);

	-- 如果报错, 把请求从队列中移除
	if not bRet then
		G_NetManager:PopRequestFromSquence(nHandlerId);		
	end
	
	return tonumber(bRet);
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