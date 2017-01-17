EventManager = class()

function EventManager:ctor()
	self.m_tbRegisterEvent = {};
end

-- 注册函数
function EventManager:Register(strEventType, funcCallback, objCall)
	
	-- 检查事件id
	if not IsString(strEventType) then
		LOG_ERROR("Register Event Failed: strEventType is nil");
		return false;
	end

	-- 检查回调函数，可不检查回调函数的对象，可以兼容全局函数的使用
	if not IsFunction(funcCallback) then
		LOG_ERROR("Register Event Failed: funcCallback is nil");
		return false;
	end

	if self.m_tbRegisterEvent[strEventType] then
		LOG_ERROR("Register Event Failed: Event duplicate...Please check event type");
		return false;
	end

	self.m_tbRegisterEvent[strEventType] = {obj = objCall, callback = funcCallback};
end

-- 触发事件
function EventManager:PostEvent(strEventName, tbParam)

	local tbEvent = self.m_tbRegisterEvent[strEventName];
	local obj = tbEvent.obj;
	local callback = tbEvent.callback;

	if obj then
		callback(obj, tbParam);
	else
		callback(tbParam);
	end
end

G_EventManager = EventManager:new()