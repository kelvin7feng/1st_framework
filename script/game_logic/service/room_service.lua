RoomService = class()

function RoomService:ctor()
	G_EventManager:Register(EVENT_ID.ROOM_EVENT.GAME_SETTLEMENT, self.GameSettlement, self);
end

function RoomService:GameSettlement(tbSettlement)

	local nErrorCode = ERROR_CODE.SYSTEM.OK;
	if not tbSettlement then
		LOG_DEBUG("RoomService - GameSettlement tbSettlement is nil")
		return nErrorCode;
	end

	if not IsTable(tbSettlement) then
		LOG_DEBUG("RoomService - GameSettlement tbSettlement is table")
		return nErrorCode;
	end

	if #tbSettlement <= 0 then
		LOG_DEBUG("RoomService - GameSettlement length of tbSettlement is 0")
		return nErrorCode;
	end

	LOG_TABLE(tbSettlement);
	local nUserId = nil;
	local nCount = nil;
	local objUser = nil;
	for _, tbUserInfo in ipairs(tbSettlement) do
		nUserId = tbUserInfo[1];
		nCount = tbUserInfo[2];
		objUser = G_UserManager:GetUserObject(nUserId);

		--LOG_DEBUG("before gold:" .. objUser:GetGold())
		if nCount > 0 then
			objUser:AddGold(nCount);
		else
			objUser:CostGold(math.abs(nCount));
		end
		--LOG_DEBUG("after gold:" .. objUser:GetGold())
		G_UserManager:SaveUserData(objUser);
	end
end

G_RoomService = RoomService:new()