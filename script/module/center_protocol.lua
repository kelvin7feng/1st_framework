
function ClientRequest(nHandlerId, nEventId, nSequenceId, tbParam)

	if not IsTable(tbParam) then
		LOG_ERROR("parameter of request is nil...")
		return 0;
	end

	LOG_INFO("nHandlerId:" .. nHandlerId);
	LOG_INFO("nEventId:" .. nEventId);
	LOG_INFO("tbParam:" .. json.encode(tbParam));
	G_NetManager:SetCurrentHandlerId(nHandlerId);

	local tbRet = {G_EventManager:DispatcherEvent(nEventId, tbParam)};
	local nErrorCode = table.remove(tbRet,1);
	G_NetManager:SendToLogicServer(nSequenceId, nEventId, nErrorCode, nHandlerId, tbRet);

	LOG_INFO("error code: " .. nErrorCode);
	LOG_INFO("tbRet: " .. json.encode(tbRet))
	return 0;
end
