StoreLogic = class()

function StoreLogic:ctor()
	
end

-- 购买房卡
function StoreLogic:BuyRoomCard(objUser, nId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("StoreLogic:BuyRoomCard objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsNumber(nId) then
		LOG_WARN("StoreLogic:BuyRoomCard nId is not number");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查参数的合法性
	local bIsOk = self:CheckIdLegal(nId);
	if not bIsOk then
		LOG_WARN("StoreLogic:BuyRoomCard nId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查金币是否足够
	local nGoldPrice = G_ConfigManager:GetConfig(TableConfigName.STORE, nId, ConfigTableFieldName.Store.PRICE);
	if not nGoldPrice or nGoldPrice < 0 then
		LOG_ERROR("StoreLogic:BuyRoomCard nGoldPrice error")
		nErrorCode = ERROR_CODE.SYSTEM.CONFIG_ERROR;
		return nErrorCode;
	end

	local nUserGold = objUser:GetGold();
	if nGoldPrice > nUserGold then
		LOG_WARN("StoreLogic:BuyRoomCard gold is not enough");
		nErrorCode = ERROR_CODE.SYSTEM.GOLD_IS_NOT_ENOUGH;
		return nErrorCode;
	end

	-- 检查配置是否有误
	local nRoomCardCount = G_ConfigManager:GetConfig(TableConfigName.STORE, nId, ConfigTableFieldName.Store.ROOM_CARD_COUNT);
	if nRoomCardCount <= 0 then
		LOG_ERROR("StoreLogic:BuyRoomCard nRoomCardCount error")
		nErrorCode = ERROR_CODE.SYSTEM.CONFIG_ERROR;
		return nErrorCode;
	end

	-- 当前房卡数量
	local nCurrentCount = objUser:GetRoomCard();

	-- 先扣金币
	local nGoldBalance = nUserGold - nGoldPrice;
	objUser:CostGold(nGoldPrice);

	-- 增加房卡
	local nTotalRoomCard = nCurrentCount + nRoomCardCount;
	objUser:AddRoomCard(nRoomCardCount);

	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode, nTotalRoomCard, nGoldBalance;
end

-- 检查配置是否存在
function StoreLogic:CheckIdLegal(nId)
	local bIsOk = false;
	if not nId then
		return bIsOk;
	end

	local tbConfig = G_ConfigManager:GetConfig(TableConfigName.STORE, tostring(nId));
	if tbConfig then
		bIsOk = true;
	end

	return bIsOk;
end

G_StoreLogic = StoreLogic:new()
