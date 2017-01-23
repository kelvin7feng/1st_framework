UserData = class()

function UserData:ctor(nUserId, tbGameData)

	self.m_bIsDirty = false;
	self.m_nUserId = nUserId;
	self.m_tbGameData = tbGameData;

	--[[self.meta_table = {}
	function self.meta_table.__newindex()
		LOG_ERROR("UserData read only...")
		return ;
	end--]]
end

-- 获取玩家Id
function UserData:GetUserId()
	return self.m_nUserId;
end

-- 获取玩家Id
function UserData:GetGameData()
	return self.m_tbGameData;
end

-- 获取玩家表数据
function UserData:GetGameTable(strTableName)
	if not IsString(strTableName) then
		LOG_ERROR("strTableName is nil!")
		return nil
	end

	local tbGameData = self:GetGameData()
	if not tbGameData then
		LOG_ERROR("tbGameData is nil!")
		return nil;
	end

	return tbGameData[strTableName];
end

-- 获取玩家字段数据
function UserData:GetGameField(strTableName, ...)
	local tbFieldArgs = {...}

	if not IsString(strTableName) then
		LOG_ERROR("GetGameField:strTableName is nil...");
		return nil;
	end

	local tbGameTableData = self:GetGameTable(strTableName);
	if not tbGameTableData then
		LOG_ERROR("GetGameField:tbGameTableData is nil...");
		return nil
	end

	local bIsOk = true;
	for nIndex, field in ipairs(tbFieldArgs) do
		if not field then
        	LOG_ERROR("field is nil at index :" .. nIndex);
        	bIsOk = false;
        	break;
		end	
	end

	if not bIsOk then
		return nil;
	end

	local tbTempData = tbGameTableData;
	for _, field in ipairs(tbFieldArgs) do
		if tbTempData[field] then
			tbTempData = tbTempData[field];	
		end
	end

	return tbTempData;
end

--[[
Desciption: 修改数据表的值
@param strTableName: 表名
@param ...: 可变参数, 前若干个是字段，最后一个是修改的值
--]]
function UserData:SetGameField(strTableName, ...)
	local tbFieldArgs = {...}

	if not IsString(strTableName) then
		LOG_ERROR("GetGameField:strTableName is nil...");
		return nil;
	end

	local tbGameTableData = self:GetGameTable(strTableName);
	if not tbGameTableData then
		LOG_ERROR("GetGameField:tbGameTableData is nil...");
		return nil
	end

	local bIsOk = true;
	for nIndex, field in ipairs(tbFieldArgs) do
		if not field then
        	LOG_ERROR("field is nil at index :" .. nIndex);
        	bIsOk = false;
        	break;
		end
	end

	if not bIsOk then
		return nil;
	end

	-- 检查字段是否存在
	local bParamIsOk = false;
	local tbTempData = tbGameTableData;
	for nIndex, field in ipairs(tbFieldArgs) do
		if not IsTable(tbTempData[field]) and nIndex == #tbFieldArgs then
			bParamIsOk = true;
		end
	end

	if bParamIsOk then
		self:SetFieldRecursively(tbGameTableData, unpack(tbFieldArgs));
		self:SetDirty(true);
	end
end

-- 设置脏数据
function UserData:SetDirty(bIsDirty)
	self.bIsDirty = bIsDirty
end

-- 是否是脏数据
function UserData:IsDirty()
	return self.bIsDirty
end

-- 修改数据表的值,调用该函数前必须先检查所有参数再调用
function UserData:SetFieldRecursively(tb, ...)
    local tbArgs = {...};
    local strField = table.remove(tbArgs, 1);
    if type(tb[strField]) == "table" then
        SetField(tb[strField], unpack(tbArgs));
    else
        tb[strField] = tbArgs[#tbArgs];
    end
end

-- 获取玩家的金币
function UserData:GetGold()
	local nVal = self:GetGameField(GAME_DATA_TABLE_NAME.BASE_INFO, GAME_DATA_FIELD_NAME.BaseInfo.GOLD);
	return nVal;
end

-- 获取玩家的金币
function UserData:SetGold(nVal)
	self:SetGameField(GAME_DATA_TABLE_NAME.BASE_INFO, GAME_DATA_FIELD_NAME.BaseInfo.GOLD, nVal);
end

-- 增加玩家的金币
function UserData:AddGold(nAddVal)

	if nAddVal < 0 then
		LOG_WARN("Add gold is less than 0")
		return false
	end

	local nVal = self:GetGold() + nAddVal;
	self:SetGold(nVal);
end

-- 消耗玩家的金币
function UserData:CostGold(nCostVal)
	if nCostVal < 0 then
		LOG_WARN("Cost gold is less than 0")
		return false
	end

	local nVal = self:GetGold() + nAddVal;
	self:SetGold(nVal);
end


