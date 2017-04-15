CardHelperTest = class()

function CardHelperTest:ctor()
	self.m_tbCommonCard = {
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
		0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D,
		0x4E, 0x4F
	}

	self.objBullShuffler = BullFightingShuffler:new()
end	

function CardHelperTest:TestGetPoint()
	for _, nCard in ipairs(self.m_tbCommonCard) do
		LOG_INFO(nCard .. "----->" .. G_CardHelper:GetPoint(nCard))
	end
end

function CardHelperTest:TestBull()
	self.objBullShuffler:Shuffle(1,5)
	local tbCard = self.objBullShuffler.m_tbShufflerResult[1]
	local bIsBull, nBullPoint, nMaxCard = G_BullFightingCardHelper:GetBullPoint(tbCard);
	LOG_TABLE({bIsBull, nBullPoint, nMaxCard});
end

function CardHelperTest:TestCompare()
	self.objBullShuffler:Shuffle(2,5)
	local tbCard1 = self.objBullShuffler.m_tbShufflerResult[1]
	local tbCard2 = self.objBullShuffler.m_tbShufflerResult[2]
	local bFormerWin, bWinOdds = G_BullFightingCardHelper:CompareCard(tbCard1, tbCard2);
	LOG_TABLE({bFormerWin, bWinOdds})
end

G_CardHelperTest = CardHelperTest:new()