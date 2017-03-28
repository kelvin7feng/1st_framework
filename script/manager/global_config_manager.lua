GlobalConfigManager = class()

function GlobalConfigManager:ctor()
	self.m_tbGlobalConfig = {}

	-- 注册协议
	G_EventManager:Register(EVENT_ID.LOGIN_SERVER.UPDATE_GLOBAL_USER_ID, self.OnUpdateUserGlobalId, self);
end

function GlobalConfigManager:Init()
	self:InitUserGlobalId()	
end

-- 更新全局玩家ID
function GlobalConfigManager:OnUpdateUserGlobalId(nUserGlobalId)
	if not IsNumber(nUserGlobalId) then
		LOG_WARN("OnCreateUser nUserGlobalId is not number");
		return ;
	end

	if nUserGlobalId < self:GetUserGlobalId() then
		LOG_WARN("OnCreateUser nUserGlobalId is less than current global Id");
		return ;
	end

	self:SetUserGlobalId(nUserGlobalId, true);
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
	self:NoticeLogicServer(nUserGlobalId);
end

-- 通知逻辑服更新当前最大玩家Id
function GlobalConfigManager:NoticeLogicServer(nUserGlobalId)
	G_NetManager:SendToLogicServerFromLogin(0, EVENT_ID.LOGIN_SERVER.UPDATE_GLOBAL_USER_ID, ERROR_CODE.SYSTEM.OK, 0, {nUserGlobalId})
end

-- 设置全局玩家Id
function GlobalConfigManager:GetUserGlobalId()
	return self:GetConfigField(DATABASE_TABLE_GLOBAL_FIELD.USER_ID);
end

-- 设置全局玩家Id
function GlobalConfigManager:SetUserGlobalId(nUserGlobalId, bOnlyCache)
	local nUserGlobalId = tonumber(nUserGlobalId);
	if not nUserGlobalId or (nUserGlobalId and nUserGlobalId == 0) then
		nUserGlobalId = DATABASE_TABLE_GLOBAL_DEFALUT[DATABASE_TABLE_GLOBAL_FIELD.USER_ID]
	end

	self:SetConfigField(DATABASE_TABLE_GLOBAL_FIELD.USER_ID, nUserGlobalId, bOnlyCache);
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
function GlobalConfigManager:SetConfigField(strField, val, bOnlyCache)
	self.m_tbGlobalConfig[strField] = val;

	LOG_DEBUG("Cache " .. strField .. ":" .. val);
	if not bOnlyCache then
		G_GlobalRedis:SetValue(0, 0, strField, val);
	end
end

-- 设置字段
function GlobalConfigManager:GetConfigField(strField)
	return self.m_tbGlobalConfig[strField];
end

G_GlobalConfigManager = GlobalConfigManager:new()