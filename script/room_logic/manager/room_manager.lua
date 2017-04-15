RoomManager = class()

function RoomManager:ctor()
	self.m_tbRoomList = {}
	self.m_tbTableMap = {}
	self.m_tbUserTableMap = {}
	-- 台号Id生成器
	self.m_objTableIdGenerator = IdGenerator:new(100000,999999);

	G_EventManager:Register(EVENT_ID.CLIENT_ENTER_GAME.ENTER_ROOM, self.ClientEnterRoom, self);
end

function RoomManager:ClientEnterRoom(tbGameData, nHandlerId, nGameType, nRoomId)

	if not self:IsRoomOpen(nGameType, nRoomId) then
		self:CreateRoom(nGameType, nRoomId)
	end

	-- 强制同步玩家数据, 以逻辑服数据为准
	self:UpdateUserData(tbGameData, nHandlerId);
	local objUser = G_UserManager:CacheUserObject(tbGameData);
	local nTableId = self:FindATable(nGameType, nRoomId);
	local nUserId = objUser:GetUserId();
	if nTableId and nUserId then
		-- 安排桌子坐下
		self:SitDown(nTableId, nUserId);
	end

	local objTable = self:GetTableById(nTableId);
	objTable:CheckState();

	-- to do:游戏开始，把数据返回到客户端
	local tbData = objTable:GetClientDataByState();
	self:SendDataToUserOfTable(nTableId, EVENT_ID.CLIENT_ENTER_GAME.ENTER_ROOM, tbData);

end

-- 更新玩家数据
function RoomManager:UpdateUserData(tbGameData, nHandlerId)
	local objUser = G_UserManager:CacheUserObject(tbGameData);
	local nUserId = objUser:GetUserId();
	G_NetManager:UpdateHandlerIdAndUserId(nUserId, nHandlerId);
end

-- 获取玩家所在的桌子
function RoomManager:GetUserTable(nUserId)
	return self.m_tbUserTableMap[nUserId];
end

-- 安排坐下
function RoomManager:SitDown(nTableId, nUserId)
	local objTable = self:GetTableById(nTableId);
	objTable:SitDown(nUserId);
	self.m_tbUserTableMap[nUserId] = objTable;
end

-- 根据Id获取桌子
function RoomManager:GetTableById(nTableId)
	return self.m_tbTableMap[nTableId];
end

-- 找桌子, to do: 需要根据当前桌子的人数创建房间
function RoomManager:FindATable(nGameType, nRoomId)

	local nTableId = self:GetAvailableTable(nGameType, nRoomId);

	if not nTableId then
		nTableId = self:CreateTable(nGameType, nRoomId);
	end

	return nTableId;
end

-- 找一张有空位的桌子
function RoomManager:GetAvailableTable(nGameType, nRoomId)
	local tbTables = self:GetAllTable(nGameType, nRoomId);

	local nTableId = nil;
	if CountTab(tbTables) <= 0 then
		LOG_INFO("There are no table at the room.")
		return nTableId;
	end

	local objTableTemp = nil;
	for _, nTempId in ipairs(tbTables) do
		objTableTemp = self:GetTableById(nTempId);
		if not objTableTemp:IsFull() then
			nTableId = nTempId;
			break;
		end
	end

	if not nTableId then
		LOG_INFO("All of table are full");
	end

	return nTableId;
end

-- 在房间里开一张桌子
function RoomManager:SetNewTableAtRoom(nGameType, nRoomId, nTableId)
	local tbTables = self:GetAllTable(nGameType, nRoomId);
	table.insert(tbTables, nTableId);
end

-- 获取所有桌子
function RoomManager:GetAllTable(nGameType, nRoomId)
	return self.m_tbRoomList[nGameType][nRoomId];
end

-- 获取一个台号
function RoomManager:GetTableId()
	return self.m_objTableIdGenerator:GetOne();
end

-- 创建一张台
function RoomManager:CreateTable(nGameType, nRoomId)
	
	local nId = self:GetTableId();
	local objTable = nil;
	
	if nGameType == GAME_TYPE_DEF.BULL_FIGHTING then
		objTable = BullFightingTableClass:new(nId);
	end

	objTable:SetGameType(nGameType);
	objTable:SetRoomId(nRoomId);

	self:CacheTable(objTable);
	self:SetNewTableAtRoom(nGameType, nRoomId, nTableId)
	return nId;
end

-- 设置桌子
function RoomManager:CacheTable(objTable)
	local nId = objTable:GetTableId();
	self.m_tbTableMap[nId] = objTable;
end

-- 获取房间里的桌子数
function RoomManager:GetSeatedTableCount(nGameType, nRoomId)
	local nCount = CountTab(self.m_tbRoomList[nGameType][nRoomId]);
	return nCount;
end

-- 创建房间
function RoomManager:CreateRoom(nGameType, nRoomId)
	if not self.m_tbRoomList[nGameType] then
		self.m_tbRoomList[nGameType] = {}
	end

	if not self.m_tbRoomList[nGameType][nRoomId] then
		self.m_tbRoomList[nGameType][nRoomId] = {}
	end
end

-- 检查房间是否开放
function RoomManager:IsRoomOpen(nGameType, nRoomId)
	local bIsOpen = false;
	if self.m_tbRoomList[nGameType] and self.m_tbRoomList[nGameType][nRoomId] then
		bIsOpen = true;
	end

	return bIsOpen;
end

-- 把数据发送给桌子上的每一个玩家
function RoomManager:SendDataToUserOfTable(nTableId, nEventType, tbData)
	local nHandlerId = nil;
	local objTable = self:GetTableById(nTableId);
	local tbUserId = objTable:GetSeatUserId();
	for _, nUserId in ipairs(tbUserId) do
		nHandlerId = G_NetManager:GetHandlerId(nUserId);
		if nHandlerId then
			G_NetManager:SendToGatewayFromRoom(0, nEventType, 0, nHandlerId, tbData)
		end
	end
end

-- 把数据发送给逻辑服
function RoomManager:SendDataToLogic(nEventType, tbData)
	G_NetManager:SendToLogicServerFromRoom(0, nEventType, 0, 0, tbData)
end

G_RoomManager = RoomManager:new()