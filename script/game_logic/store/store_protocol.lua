StoreProtocol = class()

function StoreProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_STORE.BUY_ROOM_CARD, self.ClientBuyRoomCard, self);
end

-- 客户端更新头像协议
function StoreProtocol:ClientBuyRoomCard(nId)
	
	LOG_DEBUG("StoreProtocol:ClientBuyRoomCard")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nId) then
		LOG_WARN("StoreProtocol:ClientBuyRoomCard nId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject()
	nErrorCode = G_StoreLogic:BuyRoomCard(objUser, nId)

	return nErrorCode;
end

G_StoreProtocol = StoreProtocol:new()