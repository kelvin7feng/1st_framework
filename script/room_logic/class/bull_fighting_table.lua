BullFightingTableClass = class(TableClass)

function BullFightingTableClass:ctor()
	self.m_betHistory = {};
	self.m_objShuffler = BullFightingShuffler:new(false);
	self.m_nTotalHand = 5;		-- 庄家与闲家的总数
	self.m_nSingleHand = 5;		-- 每一手牌的数目
end

-- 玩家下注
function BullFightingTableClass:UserBet(objUser, nBet)
	
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;

	local bIsOk = self:CanBet();
	if not bIsOk then
		LOG_WARN("BullFightingTableClass:UserBet user can not bet.")
		nErrorCode = ERROR_CODE.BULL_FIGHTING.CAN_NOT_BET;
		return nErrorCode;
	end

	-- to do:记录下注
	--self:NotifyAllUserOfTable(EVENT_ID.CLIENT_BULL_FIGHTING.USER_BET, {objUser:GetUserId(), nBet});
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
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
	LOG_TABLE(tbShufflerResult);
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
	self:Shuffle(self.m_nTotalHand, self.m_nSingleHand);
	G_Timer:add_timer(self:GetTimerId(), GAME_TIMER_SPAN.BullFighting.FREE, self.FreeTimerOver, self);
end

-- 状态自动加上去
function BullFightingTableClass:StateForward()
	self:SetState(self:GetState() + 1);
end

-- 空闲状态回调
function BullFightingTableClass:FreeTimerOver()
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
end

-- 结算之后回调
function BullFightingTableClass:SettlementTimerOver()
	LOG_INFO("BullFightingTableClass - SettlementTimerOver");
	-- 检查是否还有玩家，如果有，重新开始新一局
end

-- 是否可以下注
function BullFightingTableClass:CanBet()
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