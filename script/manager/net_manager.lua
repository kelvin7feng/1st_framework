NetInfoManager = class()

function NetInfoManager:ctor()
	self.m_tbUserHanderIdMap = {};
end

function NetInfoManager:SetHandlerId(nUserId, nHandlerId)
	local bIsOk = false;
	if nHandlerId > 0 then
		bIsOk = true;
		self.m_tbUserHanderIdMap[tostring(nUserId)] = nHandlerId;	
	end	
	
	return bIsOk;
end

function NetInfoManager:GetHandlerId(nUserId)
	return self.m_tbUserHanderIdMap[tostring(nUserId)];
end

G_NetInfoManager = NetInfoManager:new()