BullFightingCardHelper = class(CardHelper)

function BullFightingCardHelper:ctor()

end

-- 比较两手牌的输赢
function BullFightingCardHelper:CompareCard(tbCard1, tbCard2)

	local nWinOdds = 0;
	local bFormerWin = false;
	local bIsBull1, nBullPoint1, nMaxCard1 = self:GetBullPoint(tbCard1);
	local bIsBull2, nBullPoint2, nMaxCard2 = self:GetBullPoint(tbCard2);

	-- 同为有牛和同为无牛的情况
	if bIsBull1 == bIsBull2 then
		-- 如果有牛, 且点数不一样, 比较点数
		if bIsBull1 and nBullPoint1 ~= nBullPoint2 then
			bFormerWin = nBullPoint1 > nBullPoint2
		else
			-- 如果无牛或有牛但点数一样,比较最大的牌
			bFormerWin = nMaxCard1 > nMaxCard2
		end
	else
		-- 有牛, 即赢
		if bIsBull1 then
			bFormerWin = true;
		else
			bFormerWin = false;
		end
	end

	-- 以胜方的点数计算赔率
	if bFormerWin then
		nWinOdds = BULL_FIGHTING_ODDS[nBullPoint1];
	else
		nWinOdds = BULL_FIGHTING_ODDS[nBullPoint2] * (-1);
	end

	return bFormerWin, nWinOdds;
end

-- 计算牌的点, 0~10, 0:为无牛, 1~9:为牛的点数, 10:牛牛
function BullFightingCardHelper:GetBullPoint(tbCard)

	local bIsTenCard = false;
	local tbTempCard = {}
	local nTempTotalPoint = 0;
	local nMaxCard = 0;
	local nBullPoint = 0;

	--LOG_INFO(json.encode(tbCard))
	-- 先把扑克整理,把10,J,Q,K,大小王改成0点
	for nIndex, nCard in ipairs(tbCard) do
		bIsTenCard = self:IsTenPointCard(nCard);
		if nCard > nMaxCard then
			nMaxCard = nCard;
		end

		if bIsTenCard then
			tbTempCard[nIndex] = 10;
		else
			tbTempCard[nIndex] = self:GetPoint(nCard);
		end

		nTempTotalPoint = nTempTotalPoint + tbTempCard[nIndex];
	end

	--LOG_INFO(json.encode(tbTempCard))
	local bIsBull, nTotalTenPoint =self:IsBull(tbTempCard);
	if bIsBull then	
		nBullPoint = math.fmod(nTempTotalPoint - nTotalTenPoint, 10);
		if nBullPoint == 0 then
			nBullPoint = 10;
		end
	end

	--[[LOG_INFO("nTempTotalPoint:" .. nTempTotalPoint);
	LOG_INFO("nTotalTenPoint:" .. nTotalTenPoint);
	LOG_INFO("nBullPoint:" .. nBullPoint);--]]

	return bIsBull, nBullPoint, nMaxCard;
end

-- 计算牌里是否有牛,5张牌任意抽取3张计算是否为10的倍数
function BullFightingCardHelper:IsBull(tbCard)

	local bIsBull = false;
	local nTempPoint = 0;
	local nBullPoint = 0;
	for i = 1, 3 do
		for j = i+1, 4 do
			for k = j+1, 5 do
				nTempPoint = tbCard[i] + tbCard[j] + tbCard[k];
				nBullPoint = math.fmod(nTempPoint, 10);
				if nBullPoint == 0 then
					bIsBull = true;
					return bIsBull, nTempPoint;
				end
			end
		end
	end

	return bIsBull, nTempPoint;
end

G_BullFightingCardHelper = BullFightingCardHelper:new()