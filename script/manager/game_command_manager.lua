GameCommandManager = class()

function GameCommandManager:ctor()
	G_EventManager:Register(EVENT_ID.CLIENT_TEST.ADD_GOLD, self.AddGold, self)
end

function GameCommandManager:AddGold(nVal)
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not IsNumber(nVal) then
		LOG_DEBUG("nval is not number...");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode
	end
	local objUser = G_UserManager:GetCurrentUserObject()
	local nGold = objUser:GetGold();
	objUser:AddGold(nVal);

	local nNewGold = objUser:GetGold();
	LOG_DEBUG("nNewGold:" .. nNewGold);
	
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode, nNewGold
end

G_GameCommandManager = GameCommandManager:new()