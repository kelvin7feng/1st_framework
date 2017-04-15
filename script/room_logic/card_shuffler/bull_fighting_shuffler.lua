BullFightingShuffler = class(Shuffler);

function BullFightingShuffler:ctor(bNeedJoker)
	self:SetNeedJoker(bNeedJoker)
	self:InitCard();
end

-- 获取卡的数量
function BullFightingShuffler:GetGameCardCount()
	return CountTab(self.m_tbGameCard);
end

-- 获取当前牌的结果
function BullFightingShuffler:GetGameCard()
	return self.m_tbShufflerResult;
end

-- 洗牌
function BullFightingShuffler:Shuffle(nTotolPlayer, nSingleCount)
	if not IsNumber(nTotolPlayer) then
		LOG_ERROR("Shuffler:shuffle nTotolPlayer is not number.")
		return;
	end

	if nTotolPlayer <= 0 then
		LOG_ERROR("Shuffler:shuffle nTotolPlayer is less than 0.")
		return;
	end

	if not IsNumber(nSingleCount) then
		LOG_ERROR("Shuffler:shuffle nSingleCount is not number.")
		return;
	end

	if nSingleCount <= 0 then
		LOG_ERROR("Shuffler:shuffle nSingleCount is less than 0.")
		return;
	end

	local nCardCount = self:GetGameCardCount();
	if nTotolPlayer * nSingleCount > nCardCount then
		LOG_ERROR("Shuffler:shuffle nCardCount is out of range.")
		return;
	end

	local nTempIndex = nil;
	local nTempCard = nil;

	-- 先随机,把牌打乱
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)));
	for i = 1, nCardCount do
		nTempIndex = math.random(1, nCardCount);
		if i ~= nTempIndex then
			nTempCard = self.m_tbGameCard[nTempIndex];
			self.m_tbGameCard[nTempIndex] = self.m_tbGameCard[i];
			self.m_tbGameCard[i] = nTempCard;
		end
	end

	-- 模拟发牌,直接一手一手牌地发
	self.m_tbShufflerResult = {};
	local nTempIndex = 1;
	for i = 1, nTotolPlayer do
		local tbSingleHand = {};
		for j = 1, nSingleCount do
			table.insert(tbSingleHand, self.m_tbGameCard[nTempIndex]);
			nTempIndex = nTempIndex + 1;
		end
		table.insert(self.m_tbShufflerResult, tbSingleHand);
	end

	return self.m_tbShufflerResult;
end