-- 提供一些常用的redis接口

RedisInterface = class()

function RedisInterface:ctor(strDbTableName)
	self.m_strRedisTableName = strDbTableName;
end

function RedisInterface:GetRedisTableName()
	return self.m_strRedisTableName;
end

function RedisInterface:GetValue(nUserId, nEventType, strKey)

	if IsNumber(strKey) then
		strKey = tostring(strKey)
	elseif IsTable(strKey) then
		strKey = json.encode(strKey)
	end

	CRedis.PushRedisGet(nUserId, nEventType, self:GetRedisTableName(), strKey);
end

function RedisInterface:SetValue(nUserId, nEventType, strKey, strValue)

	if IsNumber(strValue) then
		strValue = tostring(strValue)
	elseif IsTable(strValue) then
		strValue = json.encode(strValue)
	end
	
	CRedis.PushRedisSet(nUserId, nEventType, self:GetRedisTableName(), strKey, strValue);
end

function RedisInterface:DeleteValue(nUserId, nEventType, strKey)

	if IsNumber(strKey) then
		strKey = tostring(strKey)
	elseif IsTable(strKey) then
		strKey = json.encode(strKey)
	end

	CRedis.PushRedisGet(nUserId, nEventType, self:GetRedisTableName(), strKey);
end

G_GlobalRedis = RedisInterface:new(DATABASE_TABLE_NAME.GLOBAL)
G_AccountRedis = RedisInterface:new(DATABASE_TABLE_NAME.ACCCUNT)
G_RegisterRedis = RedisInterface:new(DATABASE_TABLE_NAME.REGISTER)
G_GameDataRedis = RedisInterface:new(DATABASE_TABLE_NAME.GAME_DATA)
