GlobalConfigManager = class()

function GlobalConfigManager:ctor()
	self.m_tbGlobalConfig = {}
end

function GlobalConfigManager:Init()
	self:InitUserGlobalId()	
end

-- 初始化全局玩家Id
function GlobalConfigManager:InitUserGlobalId()
	if not self:CheckConfigField(DATABASE_TABLE_GLOBAL_FIELD.USER_ID) then
		G_GlobalRedis:GetValue(0, EVENT_ID.GLOBAL_CONFIG.GET_USER_GLOBAL_ID, DATABASE_TABLE_GLOBAL_FIELD.USER_ID);
	end
end

-- 全局玩家Id自增
function GlobalConfigManager:IncrementGlobalUserId()
	local nUserGlobalId = self:GetUserGlobalId() + 1;
	self:SetUserGlobalId(nUserGlobalId);
end

-- 设置全局玩家Id
function GlobalConfigManager:GetUserGlobalId()
	return self:GetConfigField(DATABASE_TABLE_GLOBAL_FIELD.USER_ID);
end

-- 设置全局玩家Id
function GlobalConfigManager:SetUserGlobalId(nUserGlobalId)
	local nUserGlobalId = tonumber(nUserGlobalId);
	if not nUserGlobalId or (nUserGlobalId and nUserGlobalId == 0) then
		nUserGlobalId = DATABASE_TABLE_GLOBAL_DEFALUT[DATABASE_TABLE_GLOBAL_FIELD.USER_ID]
	end

	self:SetConfigField(DATABASE_TABLE_GLOBAL_FIELD.USER_ID, nUserGlobalId)
end

-- 检查全局配置是否存在
function GlobalConfigManager:CheckConfigField(strField)
	if self.m_tbGlobalConfig[strField] then
		return true;
	else
		return false;
	end
end

-- 设置字段
function GlobalConfigManager:SetConfigField(strField, val)
	self.m_tbGlobalConfig[strField] = val;

	LOG_DEBUG("set " .. strField .. ":" .. val);
	G_GlobalRedis:SetValue(0, 0, strField, val);
end

-- 设置字段
function GlobalConfigManager:GetConfigField(strField)
	return self.m_tbGlobalConfig[strField];
end

G_GlobalConfigManager = GlobalConfigManager:new()