NetManager = class()

function NetManager:ctor()
	self.m_tbUserHanderIdMap = {};
	self.m_tbHanderIdUserMap = {};
	self.m_tbRequestSquence = {};
	self.m_nCurrentHandlerId = nil;
end

function NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam)
	if not self.m_tbRequestSquence[tostring(nHandlerId)] then
		self.m_tbRequestSquence[tostring(nHandlerId)] = {};
	end

	table.insert(self.m_tbRequestSquence[tostring(nHandlerId)], {nSequenceId, tbParam});
	LOG_DEBUG("set m_tbRequestSquence:" .. json.encode(self.m_tbRequestSquence));
end

function NetManager:PopRequestFromSquence(nHandlerId)

	local tbRequest = table.remove(self.m_tbRequestSquence[tostring(nHandlerId)], 1);
	if table.maxn(self.m_tbRequestSquence[tostring(nHandlerId)]) == 0 then
		self.m_tbRequestSquence[tostring(nHandlerId)] = nil;
	end

	LOG_DEBUG("PopRequestFromSquence:" .. json.encode(self.m_tbRequestSquence));

	local nSequenceId = tbRequest[1];
	return nSequenceId;
end

function NetManager:GetSquenceIdFromSquence(nHandlerId)

	if not nHandlerId then
        LOG_ERROR("nHandlerId is nil");
		return 0;
	end

	LOG_DEBUG("nHandlerId:"..nHandlerId)
	LOG_TABLE(self.m_tbRequestSquence)
	if not self.m_tbRequestSquence[tostring(nHandlerId)] then
		return 0;
	end

	local tbRequest = self.m_tbRequestSquence[tostring(nHandlerId)][1];
	if not tbRequest then
		return 0;
	end
	
	if table.maxn(self.m_tbRequestSquence[tostring(nHandlerId)]) == 0 then
		self.m_tbRequestSquence[tostring(nHandlerId)] = nil;
	end

	local nSequenceId = tbRequest[1];
	return nSequenceId;
end

function NetManager:GetParamFromSquence(nHandlerId)

	local tbRequest = self.m_tbRequestSquence[tostring(nHandlerId)][1];
	if table.maxn(self.m_tbRequestSquence[tostring(nHandlerId)]) == 0 then
		self.m_tbRequestSquence[tostring(nHandlerId)] = nil;
	end

	local tbParam = tbRequest[2];
	return tbParam;
end

function NetManager:SetCurrentHandlerId(nHandlerId)
	self.m_nCurrentHandlerId = nHandlerId;
end

function NetManager:GetCurrentHandlerId()
	return self.m_nCurrentHandlerId;
end

function NetManager:SetHandlerId(nUserId, nHandlerId)
	local bIsOk = false;
	if nHandlerId > 0 then
		bIsOk = true;
		self.m_tbUserHanderIdMap[tostring(nUserId)] = nHandlerId;	
	end	
	
	return bIsOk;
end

function NetManager:GetHandlerId(nUserId)
	return self.m_tbUserHanderIdMap[tostring(nUserId)];
end

function NetManager:SetUserId(nHandlerId, nUserId)
	local bIsOk = false;
	if nHandlerId > 0 then
		bIsOk = true;
		self.m_tbHanderIdUserMap[tostring(nHandlerId)] = nUserId;	
	end	
	
	return bIsOk;
end

function NetManager:GetUserId(nHandlerId)
	return self.m_tbHanderIdUserMap[tostring(nHandlerId)];
end

function NetManager:SendToCenter(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	local nLength = 1
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
		nLength = string.len(strRetParam)
	end

	self:PopRequestFromSquence(nHandlerId);
	CNet.SendToCenter(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength, strRetParam or "");
end

function NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	local nLength = 1
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
		nLength = string.len(strRetParam)
	end

	self:PopRequestFromSquence(nHandlerId);
	CNet.SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength, strRetParam or "");
end

function NetManager:SendToLogicServer(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	local nLength = 1
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
		nLength = string.len(strRetParam)
	end

	self:PopRequestFromSquence(nHandlerId);
	CNet.SendToLogicServer(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength, strRetParam or "");
end

function NetManager:ResetRequest(nHandlerId)
	self:PopRequestFromSquence(nHandlerId);
end

function NetManager:SetServerTypeToHandlerId(nServerType, nHandlerId)
	
	if not IsNumber(nServerType) or not IsNumber(nHandlerId) then
		return;
	end
	return CNet.SetServerTypeToHandlerId(nServerType, nHandlerId);
end

function NetManager:SendNoticeToUser(nEventType, nErrorCode, nUserId, strRetParam)
	
	local nLength = 1
	local nSequenceId = 0;
	local nHandlerId = G_NetManager:GetHandlerId(nUserId);
	
	if not nHandlerId then
		LOG_DEBUG("User is offline...")
		return ;
	end

	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
		nLength = string.len(strRetParam)
	end

	CNet.SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength, strRetParam or "");

end

G_NetManager = NetManager:new()