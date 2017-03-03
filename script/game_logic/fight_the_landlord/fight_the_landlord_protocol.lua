FightTheLandlordProtocol = class()

function FightTheLandlordProtocol:ctor()
	-- 注册客户端协议
	G_EventManager:Register(EVENT_ID.CLIENT_TEST.ENTER_ROOM, self.ClientEnterRoom, self);
end

-- 客户端请求进入房间协议
function FightTheLandlordProtocol:ClientEnterRoom()
	
	LOG_DEBUG("FightTheLandlordProtocol:ClientBuyRoomCard")
	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	local objUser = G_UserManager:GetCurrentUserObject();

	local nRetCode = G_FightTheLandlordLogic:CheckEnterRoom();
	if nRetCode == ERROR_CODE.SYSTEM.OK then
		nErrorCode = ERROR_CODE.NET.LOGIN_TO_ROOM_SERVER;
	else
		nErrorCode = nRetCode;
	end

	return nErrorCode, objUser:GetUserId(), GAME_TYPE_DEF.FIGHT_THE_LANDLORD;
end

G_FightTheLandlordProtocol = FightTheLandlordProtocol:new()