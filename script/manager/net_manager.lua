NetManager = class()

function NetManager:ctor()
	self.m_tbUserHanderIdMap = {};
	self.m_tbRequestSquence = {}
end

function NetManager:PushRequestToSquence(nHandlerId, nSequenceId, tbParam)
	if not self.m_tbRequestSquence[tostring(nHandlerId)] then
		self.m_tbRequestSquence[tostring(nHandlerId)] = {};
	end

	table.insert(self.m_tbRequestSquence[tostring(nHandlerId)], {nSequenceId, tbParam});
	LOG_INFO("set m_tbRequestSquence:" .. json.encode(self.m_tbRequestSquence));
end

function NetManager:PopRequestFromSquence(nHandlerId)

	local tbRequest = table.remove(self.m_tbRequestSquence[tostring(nHandlerId)], 1);
	if table.maxn(self.m_tbRequestSquence[tostring(nHandlerId)]) == 0 then
		self.m_tbRequestSquence[tostring(nHandlerId)] = nil;
	end

	local nSequenceId = tbRequest[1];
	return nSequenceId;
end

function NetManager:GetSquenceIdFromSquence(nHandlerId)

	local tbRequest = self.m_tbRequestSquence[tostring(nHandlerId)][1];
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

function NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength, strRetParam)
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end
	
	self:PopRequestFromSquence(nHandlerId);
	CNet.SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength or 1, strRetParam or "");
end

G_NetManager = NetManager:new()