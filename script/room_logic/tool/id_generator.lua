
--[[
	ID生成器:根据参数区间生成乱序的数组
--]]

IdGenerator = class()

function IdGenerator:ctor(nMin, nMax)
	
	if nMin >= nMax then
		LOG_ERROR("min is greater than max");
		return;
	end

	self.m_nMin = nMin;
	self.m_nMax = nMax;
	self.m_nRange = nMax + 1 - nMin;
	self.m_tbIds = nil;

	self:Init();
end

function IdGenerator:GetMin()
	return self.m_nMin;
end

function IdGenerator:GetMax()
	return self.m_nMax;
end

function IdGenerator:GetRange()
	return self.m_nRange;
end

function IdGenerator:GetOne()
	return table.remove(self.m_tbIds, 1);
end

function IdGenerator:Return(nId)
	if nId >= self.m_nMin and nId <= self.m_nMax then
		table.insert(self.m_tbIds, nId);
	end
end

function IdGenerator:Init()
	local nMin = self:GetMin();
	local nMax = self:GetMax();
	local nRange = self:GetRange();

	local tabRet ={};
	local tabTemp = {};
	local nTop = nMax;
	-- 让随机种子变化，如果时间戳，短时间同时生成的变化很小
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)));
	for i = 1, nRange do
		local nRandResult = math.random(nMin, nTop);
		local nResult = tabTemp[nRandResult] or nRandResult;
		table.insert(tabRet, nResult);
		if nRandResult ~= nTop then
	    	tabTemp[nRandResult] = tabTemp[nTop] or nTop;
	    end

	    nTop = nTop - 1;
	end

    self.m_tbIds = tabRet;
end