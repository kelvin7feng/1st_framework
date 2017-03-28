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

function NetManager:GetAllOnlineUserId()
	local tbUserId = {}
	
	for strUserId, _ in pairs(self.m_tbUserHanderIdMap) do
		table.insert(tbUserId, tonumber(strUserId));
	end

	return tbUserId;
end

function NetManager:ReleaseHandler(nUserId)
	local nHandlerId = self:GetHandlerId(nUserId);
	if nHandlerId then
		-- to do: 通知网关移除，或者在网关处添加心跳包功能
		self:SetUserId(nHandlerId, nil);
	end
end

function NetManager:ExistOldHanlder(nUserId)
	local bExist = false;
	local nHandlerId = self:GetHandlerId(nUserId);
	if nHandlerId then
		bExist = true;
	end

	return bExist;
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

-- 发送数据到指定服务器
function NetManager:SendToServer(nServerType, nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	if not IsNumber(nServerType) then
		LOG_WARN("SendToServer nServerType is not number");
		return ;
	end

	if nServerType < SERVER_TYPE_DEF.CENTER or nServerType > SERVER_TYPE_DEF.GATEWAY then
		LOG_WARN("SendToServer nServerType does not exist");
		return ;
	end

	CNet.SendToServer(nServerType, nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam or "");
end

-- 逻辑服通过中心服转发到房间服
function NetManager:SendToRoomServerFromLogic(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end

	self:PopRequestFromSquence(nHandlerId);
	self:SendToServer(nServerType, nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam or "")
end

-- 逻辑服发送到网关
function NetManager:SendToGateway(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end

	self:PopRequestFromSquence(nHandlerId);
	self:SendToServer(SERVER_TYPE_DEF.GATEWAY, nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
end

-- 逻辑服发送到网关
function NetManager:SendToLogicServerFromLogin(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end

	self:SendToServer(SERVER_TYPE_DEF.LOGIC, 0, EVENT_ID.LOGIN_SERVER.UPDATE_GLOBAL_USER_ID, ERROR_CODE.SYSTEM.OK, 0, strRetParam);
end

-- 中心服发送到逻辑服
function NetManager:SendToLogicServer(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam)
	
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end

	self:PopRequestFromSquence(nHandlerId);
	CNet.SendToLogicServer(nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam or "");
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

function NetManager:UserIsOnline(nUserId)
	local bIsOnline = false;
	local nHandlerId = self:GetHandlerId(nUserId);
	if nHandlerId then
		bIsOnline = true;
	end

	return bIsOnline;
end

function NetManager:SendNoticeToUser(nEventType, nErrorCode, nUserId, strRetParam)
	
	local nSequenceId = 0;
	local nHandlerId = nil;
	
	if not self:UserIsOnline(nUserId) then
		LOG_DEBUG("User is offline...")
		return ;
	end

	nHandlerId = G_NetManager:GetHandlerId(nUserId);
	if strRetParam and not IsString(strRetParam) then
		strRetParam = json.encode(strRetParam);
	end

	self:SendToServer(SERVER_TYPE_DEF.GATEWAY, nSequenceId, nEventType, nErrorCode, nHandlerId, strRetParam or "");

end

G_NetManager = NetManager:new()