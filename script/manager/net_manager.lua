NetManager = class()

function NetManager:ctor()
	self.m_tbUserHanderIdMap = {};
	self.m_tbRequestSquence = {}
end

function NetManager:PushRequestToSquence(nHandlerId, nSequenceId)
	if not self.m_tbRequestSquence[tostring(nHandlerId)] then
		self.m_tbRequestSquence[tostring(nHandlerId)] = {};
	end

	table.insert(self.m_tbRequestSquence[tostring(nHandlerId)], nSequenceId);
	LOG_INFO("set m_tbRequestSquence:" .. json.encode(self.m_tbRequestSquence));
end

function NetManager:PopRequestFromSquence(nHandlerId)

	local nSequenceId = table.remove(self.m_tbRequestSquence[tostring(nHandlerId)], 1);
	if table.maxn(self.m_tbRequestSquence[tostring(nHandlerId)]) == 0 then
		self.m_tbRequestSquence[tostring(nHandlerId)] = nil;
	end

	return nSequenceId;
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
	
	CNet.SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, nLength or 1, strRetParam or "");
end

G_NetManager = NetManager:new()