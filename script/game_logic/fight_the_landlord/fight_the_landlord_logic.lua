FightTheLandlordLogic = class()

function FightTheLandlordLogic:ctor()
	
end

-- 检查是否有资格进入游戏
function FightTheLandlordLogic:CheckEnterRoom()
	local nErrorCode = ERROR_CODE.NET.LOGIC_TO_ROOM_SERVER;
	return nErrorCode;
end

G_FightTheLandlordLogic = FightTheLandlordLogic:new()
