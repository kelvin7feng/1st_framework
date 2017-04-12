TableClass = class()

function TableClass:ctor(nId)
	self.m_nState = 0;
	self.m_nGameType = nil;
	self.m_nRoomId = nil;
	self.m_bIsFull = false;
	self.m_nTableId = nId;
	self.m_tbSeatUser = {};
	self.m_tbTableConfig = nil;
end

-- 获取当前所有玩家Id
function TableClass:GetSeatUserId()
	return self.m_tbSeatUser;
end

-- 获取当前所有玩家信息列表
function TableClass:GetSeatUserList()
	local objUser = nil;
	local tbUserList = {};
	for nIndex, nUserId in ipairs(self.m_tbSeatUser) do
		if nUserId and nUserId > 0 then
			objUser = G_UserManager:GetUserObject(nUserId);
			LOG_TABLE(objUser);
			tbUserList[nIndex] = objUser:GetClientShownData();
		else
			tbUserList[nIndex] = {};
		end
	end

	return tbUserList;
end

-- 设置状态
function TableClass:GetSeatUserCount()
	return CountTab(self.m_tbSeatUser);
end

-- 设置状态
function TableClass:SetState(nState)
	self.m_nState = nState;
end

-- 获取状态
function TableClass:GetState()
	return self.m_nState;
end

-- 坐下
function TableClass:SitDown(nUserId)
	table.insert(self.m_tbSeatUser, nUserId);
end

-- 获取Id
function TableClass:GetTableId()
	return self.m_nTableId;
end

-- 获取游戏类型
function TableClass:GetGameType()
	return self.m_nGameType or 0;
end

-- 设置游戏类型
function TableClass:SetGameType(nGameType)
	self.m_nGameType = nGameType;
end

-- 设置房间Id
function TableClass:SetRoomId(nRoomId)
	self.m_nRoomId = nRoomId;
end

-- 是否坐满了
function TableClass:IsFull()
	return self.m_bIsFull;
end

-------------------------------
-- 以下函数针对子类实现,每个游戏子类
-------------------------------

-- 根据当前状态打包客户端需要的数据
function TableClass:GetClientDataByState()
	LOG_WARN("need to overwrite by subclass");
end

-- 检查状态
function TableClass:CheckState()
	LOG_WARN("need to overwrite by subclass");
end

-- 获取客户端初始状态数据
function TableClass:GetClientInitData()
	LOG_WARN("need to overwrite by subclass");
end