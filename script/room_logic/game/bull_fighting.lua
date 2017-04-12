BullFighting = class(GameBase)

function BullFighting:ctor()
	G_EventManager:Register(EVENT_ID.CLIENT_BULL_FIGHTING.BET, self.ClientBet, self);
end

-- 客户端下注
function BullFighting:ClientBet(nBet)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nBet) then
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local objUser = G_UserManager:GetCurrentUserObject();
	local objTable = G_RoomManager:GetUserTable(objUser:GetUserId());
	return objTable:UserBet(objUser, nBet);
end

G_BullFighting = BullFighting:new();