CardHelper = class()

function CardHelper:ctor()

end

-- 获取牌的点数
function CardHelper:GetPoint(nCard)
	local nTag = 0x0F;
	return bit.band(nCard, nTag);
end

-- 判断是否为10的数字:10,J,Q,K,大小王
function CardHelper:IsTenPointCard(nCard)
	local nTag1 = 0x08;
	local nTag2 = 0x06;
	local a = bit.band(nCard, nTag1);
	local b = bit.band(nCard, nTag2);
	if a > 0 and b > 0 then
		return true;
	end

	return false;
end

G_CardHelper = CardHelper:new()