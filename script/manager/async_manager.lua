AsyncManager = class()

function AsyncManager:ctor()
	self.m_tbSquence = {};
	self.m_nSquenceId = 1;
end

-- 递增
function AsyncManager:IncrementSquenceId()
	local nTempId = math.mod(self.m_nSquenceId + 1, 10000000);
	if nTempId ==  0 then
		nTempId = 1;
	end

	self.m_nSquenceId = nTempId;
end

-- 获取队列Id
function AsyncManager:GetSquenceId()
	return self.m_nSquenceId;
end

-- Push到队列里
function AsyncManager:Push(tbParameters)
	tbParameters = tbParameters or {}
	local nSquenceId = self:GetSquenceId();
	self.m_tbSquence[tostring(nSquenceId)] = tbParameters;
	self:IncrementSquenceId();

	LOG_DEBUG("AsyncManager:Push " .. json.encode(tbParameters));
	LOG_DEBUG("AsyncManager:nSquenceId " .. nSquenceId);
	return nSquenceId;
end

-- 从队列里取出
function AsyncManager:Pop(nSquenceId)
	if not IsNumber(nSquenceId) then
		LOG_ERROR("nSquenceId Is not number");
		return nil;
	end

	nSquenceId = tostring(nSquenceId);
	local tbParameters = self.m_tbSquence[nSquenceId];
	self.m_tbSquence[nSquenceId] = nil;

	return tbParameters;
end

G_AsyncManager = AsyncManager:new()