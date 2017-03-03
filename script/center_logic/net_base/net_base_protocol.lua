NetBaseProtocol = class()

function NetBaseProtocol:ctor()
	-- 注册与逻辑服的协议
	G_EventManager:Register(EVENT_ID.CENTER_SERVER.REGISTER, self.RegisterProtocol, self);
end

-- 服务器注册协议
function NetBaseProtocol:RegisterProtocol(strIp, nPort, nServerType)
	
	if not IsString(strIp) then
		LOG_WARN("NetBaseProtocol:RegisterProtocol strIp is not string");
		return ERROR_CODE.SYSTEM.PARAMTER_ERROR;
	end

	if not IsNumber(nPort) then
		LOG_WARN("NetBaseProtocol:RegisterProtocol nPort is not number");
		return ERROR_CODE.SYSTEM.PARAMTER_ERROR;
	end	
	
	if not IsNumber(nServerType) then
		LOG_WARN("NetBaseProtocol:RegisterProtocol nServerType is not number");
		return ERROR_CODE.SYSTEM.PARAMTER_ERROR;
	end

	local nHandlerId = G_NetManager:GetCurrentHandlerId();
	return G_NetBaseLogic:RegisterServer(strIp, nPort, nServerType, nHandlerId);
end

G_NetBaseProtocol = NetBaseProtocol:new()