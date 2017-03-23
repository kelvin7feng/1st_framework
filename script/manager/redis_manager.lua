-- 提供一些常用的redis接口

RedisInterface = class()

function RedisInterface:ctor(strDbTableName)
	self.m_strRedisTableName = strDbTableName;
end

function RedisInterface:GetRedisTableName()
	return self.m_strRedisTableName;
end

function RedisInterface:GetValue(nUserId, nEventType, strKey, tbParameters)

	if IsNumber(strKey) then
		strKey = tostring(strKey)
	elseif IsTable(strKey) then
		strKey = json.encode(strKey)
	end
	
	local strTableName = self:GetRedisTableName();
	local nAsyncSquenceId = G_AsyncManager:SetParameter(tbParameters, strTableName);
	CRedis.PushRedisGet(nAsyncSquenceId, nUserId, nEventType, strTableName, strKey);
end

function RedisInterface:MGetValue(nUserId, nEventType, tbKeys, tbParameters)

	local strTableName = self:GetRedisTableName();
	if #tbKeys <= 0 then
		LOG_WARN("tbKeys is empty");
		return false;
	end

	local strKeys = "";
	for nIndex, strKey in ipairs(tbKeys) do
		if nIndex == 1 then
			strKeys = string.format("%s_%s", strTableName, tostring(strKey));
		else
			strKeys = string.format("%s %s_%s", strKeys, strTableName, tostring(strKey));
		end
	end
	
	local nAsyncSquenceId = G_AsyncManager:SetParameter(tbParameters, strTableName);
	CRedis.PushRedisGets(nAsyncSquenceId, nUserId, nEventType, strKeys);
end

function RedisInterface:SetValue(nUserId, nEventType, strKey, strValue)

	if IsNumber(strValue) then
		strValue = tostring(strValue)
	elseif IsTable(strValue) then
		strValue = json.encode(strValue)
	end
	
	local strTableName = self:GetRedisTableName();
	local nAsyncSquenceId = G_AsyncManager:SetParameter(nil, strTableName);
	CRedis.PushRedisSet(nUserId, nEventType, strTableName, strKey, strValue);
end

function RedisInterface:DeleteValue(nUserId, nEventType, strKey)

	if IsNumber(strKey) then
		strKey = tostring(strKey)
	elseif IsTable(strKey) then
		strKey = json.encode(strKey)
	end

	local strTableName = self:GetRedisTableName();
	local nAsyncSquenceId = G_AsyncManager:SetParameter(nil, strTableName);
	CRedis.PushRedisGet(nUserId, nEventType, strTableName, strKey);
end

G_GlobalRedis = RedisInterface:new(DATABASE_TABLE_NAME.GLOBAL)
G_AccountRedis = RedisInterface:new(DATABASE_TABLE_NAME.ACCCUNT)
G_RegisterRedis = RedisInterface:new(DATABASE_TABLE_NAME.REGISTER)
G_GameDataRedis = RedisInterface:new(DATABASE_TABLE_NAME.GAME_DATA)
