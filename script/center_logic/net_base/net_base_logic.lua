NetBaseLogic = class()

function NetBaseLogic:ctor()
	self.tbServerMap = {}
end

-- 记录当前服务器信息
function NetBaseLogic:SetServer(strIp, nPort, nServerType)
	self.tbServerMap[tostring(nServerType)] = {strIp, nPort};
end

-- 设置到C++层里
function NetBaseLogic:SetServerTypeToHandlerId(nServerType, nHandlerId)
	G_NetManager:SetServerTypeToHandlerId(nServerType, nHandlerId);
end

-- 注册服务器信息
function NetBaseLogic:RegisterServer(strIp, nPort, nServerType, nHandlerId)
	self:SetServer(strIp, nPort, nServerType);
	self:SetServerTypeToHandlerId(nServerType, nHandlerId);
	return ERROR_CODE.SYSTEM.OK;
end

G_NetBaseLogic = NetBaseLogic:new()