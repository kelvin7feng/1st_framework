BullFightingTableClass = class(TableClass)

function BullFightingTableClass:ctor()
	self.m_objShuffler = BullFightingShuffler:new(false);
	self.m_nTotalHand = 5;		-- 庄家与闲家的总数
	self.m_nSingleHand = 5;		-- 每一手牌的数目
	self.m_tbPlayerBet = {};	-- 闲家下注总数
	self.m_tbUserBet = {};		-- 玩家下注记录
end

-- 获取洗牌器
function BullFightingTableClass:GetShuffler()
	return self.m_objShuffler;
end

function BullFightingTableClass:GetAllBet()
	return self.m_tbUserBet;
end

-- 获取玩家下注数据
function BullFightingTableClass:GetUserBet(nUserId)
	return self.m_tbUserBet[nUserId];
end

-- 获取玩家当前局下注总数
function BullFightingTableClass:GetSumOfUserBet(nUserId)
	local nCount = 0;
	local tbUserBet = self:GetUserBet(nUserId);
	if tbUserBet then
		for _,nBet in ipairs(tbUserBet) do
			nCount = nCount + nBet;
		end
	end

	return nCount;
end

-- 记录下注
function BullFightingTableClass:MarkBet(nUserId, nPosition, nBet)
	
	if nPosition > 0 and nPosition <= 4 then
		self.m_tbPlayerBet[nPosition] = self.m_tbPlayerBet[nPosition] + nBet;
		if not self.m_tbUserBet[nUserId] then
			self.m_tbUserBet[nUserId] = {0,0,0,0};
		end

		self.m_tbUserBet[nUserId][nPosition] = self.m_tbUserBet[nUserId][nPosition] + nBet;

		LOG_DEBUG("MarkBet :" ..  nUserId .. "," .. nPosition .. "," .. nBet);
	end
end

-- 玩家下注
function BullFightingTableClass:UserBet(objUser, nPosition, nBet)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if nPosition <= 0 or nPosition > 4 then
		LOG_WARN("BullFightingTableClass:UserBet nPosition is illegal.")
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local bIsOk = self:IsBetState();
	if not bIsOk then
		LOG_WARN("BullFightingTableClass:UserBet state is not betting.")
		nErrorCode = ERROR_CODE.BULL_FIGHTING.CAN_NOT_BET;
		return nErrorCode;
	end

	if not self:CheckBetOverRange(objUser, nBet) then
		LOG_WARN("BullFightingTableClass:UserBet user's gold is not enough.")
		nErrorCode = ERROR_CODE.BULL_FIGHTING.BET_IS_TOO_LARGE;
		return nErrorCode;
	end

	-- 记录下注
	local nUserId = objUser:GetUserId();
	self:MarkBet(nUserId, nPosition, nBet)

	-- 通知所有玩家:有人下注了
	--self:NotifyAllUserOfTable(EVENT_ID.CLIENT_BULL_FIGHTING.USER_BET, {objUser:GetUserId(), nBet});
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 获取最大赔率
function BullFightingTableClass:GetMaxOdds()
	return BULL_FIGHTING_ODDS[10];
end

-- 检查下注最大赔率时候是否超过玩家自身的金币
function BullFightingTableClass:CheckBetOverRange(objUser, nBet)
	local nUserGold = objUser:GetGold();
	local nUserId = objUser:GetUserId();
	local nCurrentBet = self:GetSumOfUserBet(nUserId);
	return (nUserGold > (nCurrentBet + nBet) * self:GetMaxOdds() and true) or false;
end

-- 通知当前桌子的所有玩家
function BullFightingTableClass:NotifyAllUserOfTable(nEventType, tbData)
	local nTableId = self:GetTableId();
	G_RoomManager:SendDataToUserOfTable(nTableId, nEventType, tbData);
end

-- 获取定时器的Id
function BullFightingTableClass:GetTimerId()
	return string.format("%d_%d_%d", self:GetGameType(), self:GetTableId(), self:GetState());
end

-- 洗牌
function BullFightingTableClass:Shuffle(nTotolPlayer, nSingleCount)
	local tbShufflerResult = self.m_objShuffler:Shuffle(nTotolPlayer, nSingleCount);
	-- LOG_TABLE(tbShufflerResult);
end

-- 检查状态
function BullFightingTableClass:CheckState()
	local nState = self:GetState();
	if nState == GAME_STATE_DEF.BullFighting.INIT then
		-- 检查是否有玩家，如果有，则进入下一个状态
		local nCount = self:GetSeatUserCount();
		if nCount > 0 then
			self:InitGame();
		end
		return;
	end
end

-- 初始化新一局游戏
function BullFightingTableClass:InitGame()

	self:StateForward();
	self.m_tbUserBet = {};
	self.m_tbPlayerBet = {0,0,0,0}
	self:Shuffle(self.m_nTotalHand, self.m_nSingleHand);
	G_Timer:add_timer(self:GetTimerId(), GAME_TIMER_SPAN.BullFighting.FREE, self.FreeTimerOver, self);
end

-- 状态自动加上去
function BullFightingTableClass:StateForward()
	self:SetState(self:GetState() + 1);
end

-- 空闲状态回调
function BullFightingTableClass:FreeTimerOver()
	LOG_DEBUG("BullFightingTableClass:FreeTimerOver change state to BET")
	-- 修改为下注状态
	self:StateForward();
	G_Timer:add_timer(self:GetTimerId(), GAME_TIMER_SPAN.BullFighting.BET, self.BetTimerOver, self);
end

-- 下注结束状态回调
function BullFightingTableClass:BetTimerOver()
	LOG_INFO("BullFightingTableClass - BetTimerOver");
	-- 结算, 下发结果
	self:Settlement();

	-- 修改状态
	self:StateForward();
	G_Timer:add_timer(self:GetTimerId(), GAME_TIMER_SPAN.BullFighting.SETTLEMENT, self.SettlementTimerOver, self);
end

-- 结算
function BullFightingTableClass:Settlement()
	LOG_INFO("BullFightingTableClass - Settlement");
	
	local tbPlayerResult = {}
	local tbTempResult = nil;
	local nPlayerBullPoint = nil;
	local bFormerWin = false;
	local nWinOdds = 0;
	local tbDealerCard = self:GetDealerCard();
	local tbPlayerCards = self:GetPlayerCard();

	local _, nDealerBullPoint = G_BullFightingCardHelper:GetBullPoint(tbDealerCard);
	local tbDealerInfo = {};
	tbDealerInfo.tbCard = tbDealerCard;
	tbDealerInfo.nBullPoint = nDealerBullPoint;

	for nPosition, tbPlayerCard in ipairs(tbPlayerCards) do

		_, nPlayerBullPoint = G_BullFightingCardHelper:GetBullPoint(tbPlayerCard);
		bFormerWin, nWinOdds = G_BullFightingCardHelper:CompareCard(tbPlayerCard, tbDealerCard);

		tbTempResult = {};
		tbTempResult.tbCard = tbPlayerCard;
		tbTempResult.bWin = bFormerWin;
		tbTempResult.nWinOdds = nWinOdds;
		tbTempResult.nBullPoint = nPlayerBullPoint;

		tbPlayerResult[nPosition] = tbTempResult;
	end

	-- LOG_TABLE(tbPlayerResult);

	local nCount = 0;
	local tbSettlementRecord = {}
	-- 该局游戏中所有下注记录
	local tbAllBet = self:GetAllBet();
	-- 该局游戏中所有玩家
	local tbSeatUser = self:GetSeatUserId()
	for nSeatNo, nUserId in pairs(tbSeatUser) do
		tbUserBet = tbAllBet[nUserId];
		if tbUserBet then
			nCount = 0;
			for nPosition, nBet in ipairs(tbUserBet) do
				if nBet > 0 then
					if nBet * tbPlayerResult[nPosition].nWinOdds > 0 then
						nCount = nCount + nBet * (1 - GAME_COMMISSION.BULL_FIGHTING);
					else
						nCount = nCount - nBet;
					end
				end
			end

			-- 把数值有变化的发给逻辑服
			if nCount ~= 0 then
				local objUser = G_UserManager:GetUserObject(nUserId);
				if nCount > 0 then
					objUser:AddGold(nCount);
				else
					objUser:CostGold(math.abs(nCount));
				end
				table.insert(tbSettlementRecord, {nUserId, nCount, objUser:GetGold()});
			end
		end
	end

	local tbData = {tbDealerInfo, tbPlayerResult, tbSettlementRecord};
	self:NotifyAllUserOfTable(EVENT_ID.CLIENT_BULL_FIGHTING.SETTLEMENT, tbData);
	
	--通知逻辑服更新玩家数据
	if CountTab(tbSettlementRecord) > 0 then
		G_RoomManager:SendDataToLogic(EVENT_ID.ROOM_EVENT.GAME_SETTLEMENT, {tbSettlementRecord});
	end

end

-- 获取庄家的牌
function BullFightingTableClass:GetDealerCard()
	local tbCard = self.m_objShuffler:GetGameCard();
	return tbCard[1];
end

-- 获取所有闲家的牌
function BullFightingTableClass:GetPlayerCard()
	local tbPlayerCards = {}
	local tbCard = self.m_objShuffler:GetGameCard();

	for i = 2,#tbCard do
		table.insert(tbPlayerCards, tbCard[i])
	end

	return tbPlayerCards;
end

-- 结算之后回调
function BullFightingTableClass:SettlementTimerOver()
	LOG_INFO("BullFightingTableClass - SettlementTimerOver");
	-- 检查状态，重新开始新一局，自动开局或结束
	local nCount = self:GetSeatUserCount();
	if nCount > 0 then
		self:SetState(GAME_STATE_DEF.BullFighting.INIT);
		self:CheckState();
	else
		LOG_INFO("Destroy the table");
	end
end

-- 是否可以下注
function BullFightingTableClass:IsBetState()
	return self:GetState() == GAME_STATE_DEF.BullFighting.BET;
end

-- 根据当前状态打包客户端需要的数据
function BullFightingTableClass:GetClientDataByState()
	local nState = self:GetState();
	if GAME_STATE_DEF.BullFighting.FREE == nState then
		return self:GetDataOfFreeState();
	end
end

-- 获取空闲状态显示的数据
function BullFightingTableClass:GetDataOfFreeState()
	local tbUserList = self:GetSeatUserList();
	local nState = GAME_STATE_DEF.BullFighting.FREE;
	return {nState, GAME_TIMER_SPAN.BullFighting.FREE, tbUserList};
end