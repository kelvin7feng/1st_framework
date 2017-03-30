UserInfoLogic = class()

function UserInfoLogic:ctor()
	
	G_EventManager:Register(EVENT_ID.SYSTEM.LOGOUT, self.Logout, self);
end

-- 玩家登出
function UserInfoLogic:Logout()
	local nHandlerId = G_NetManager:GetCurrentHandlerId();
	if not IsNumber(nHandlerId) then
		return 0;
	end

	G_NetManager:OnUserDisconnect(nHandlerId);
	G_UserManager:ResetCurrentUserObject();

	return ERROR_CODE.SYSTEM.OK;
end

-- 更新存款
function UserInfoLogic:UpdateBalance(objUser, nBalance)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:UpdateAvatar objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsNumber(nBalance) then
		LOG_WARN("UserInfoLogic:UpdateBalance nBalance is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 不能小于0
	if nBalance < 0 then
		LOG_WARN("UserInfoLogic:UpdateBalance nBalance less than 0");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 如果是浮点数，不给处理
	if IsFloat(nBalance) then
		LOG_WARN("UserInfoLogic:UpdateBalance nBalance is float");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	local nUserGold = objUser:GetGold();
	local nUserBalance = objUser:GetBalance();
	local nTotal = nUserGold + nUserBalance;

	-- 不能超出总额
	if nBalance > nTotal then
		nErrorCode = ERROR_CODE.USER_BASE_INFO.BALANCE_IS_OUT_OF_RANGE;
		return nErrorCode;
	end 

	local nGold = nTotal - nBalance;
	objUser:SetGold(nGold);
	objUser:SetBalance(nBalance);

	nErrorCode = ERROR_CODE.SYSTEM.OK;
	return nErrorCode, nBalance, nGold
end

-- 更新头像
function UserInfoLogic:UpdateAvatar(objUser, nAvatarId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:UpdateAvatar objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsNumber(nAvatarId) then
		LOG_WARN("UserInfoLogic:UpdateAvatar nAvatarId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查头像Id是否合法，检查是否越界
	if nAvatarId < 0 or nAvatarId > 15 then
		LOG_WARN("UserInfoProtocol:UpdateAvatar nAvatarId is out of range");
		nErrorCode = ERROR_CODE.USER_BASE_INFO.AVATAR_ID_IS_OUT_OF_RANGE;
		return nErrorCode;
	end

	local nOldAvatarId = objUser:GetAvatar();

	-- 如果旧值和修改的不一致，则修改数据
	if nOldAvatarId ~= nAvatarId then
		objUser:SetAvatar(nAvatarId);
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 更新性别
function UserInfoLogic:UpdateSex(objUser, nSex)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:UpdateSex objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsNumber(nSex) then
		LOG_WARN("UserInfoLogic:UpdateSex nSex is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查性别是否合法，检查是否越界
	if nSex ~= TYPE_SEX.FEMALE and nSex ~= TYPE_SEX.MALE then
		LOG_WARN("UserInfoProtocol:UpdateSex nSex is out of range");
		nErrorCode = ERROR_CODE.USER_BASE_INFO.SEX_IS_OUT_OF_RANGE;
		return nErrorCode;
	end

	local nOldSex = objUser:GetSex();
	
	-- 如果旧值和修改的不一致，则修改数据
	if nOldSex ~= nSex then
		objUser:SetSex(nSex);
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 更新邀请人ID
function UserInfoLogic:UpdateInviterId(objUser, nInviterId)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:UpdateInviterId objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsNumber(nInviterId) then
		LOG_WARN("UserInfoLogic:UpdateInviterId nInviterId is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查邀请人Id是否合法
	local bIsOk = G_UserInfoLogic:CheckUserIdLegal(nInviterId);
	if not bIsOk then
		LOG_WARN("UserInfoProtocol:UpdateInviterId nInviterId is out of range");
		nErrorCode = ERROR_CODE.USER_BASE_INFO.INVITER_ID_IS_OUT_OF_RANGE;
		return nErrorCode;
	end

	local nOldInviterId = objUser:GetInviterId();

	-- 如果已经填写，则不允许修改
	if nOldInviterId and nOldInviterId > 0 then
		LOG_WARN("UserInfoProtocol:UpdateInviterId nInviterId is not empty")
		nErrorCode = ERROR_CODE.USER_BASE_INFO.INVITER_ID_IS_NOT_EMPTY;
		return nErrorCode;
	end

	-- 邀请人不能为自己
	local selfUserId = objUser:GetUserId();
	LOG_DEBUG("selfUserId:" .. json.encode(selfUserId));
	if selfUserId == nInviterId then
		LOG_WARN("UserInfoProtocol:UpdateInviterId nInviterId is oneself")
		nErrorCode = ERROR_CODE.USER_BASE_INFO.INVITER_ID_IS_ONESELF;
		return nErrorCode
	end

	-- 如果旧值和修改的不一致，则修改数据
	if nOldInviterId ~= nInviterId then
		objUser:SetInviterId(nInviterId);
	end

	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 更新性别
function UserInfoLogic:UpdateNickName(objUser, strNickName)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:UpdateSex objUser is nil")
		return nErrorCode;
	end

	-- 检查类型
	if not IsString(strNickName) then
		LOG_WARN("UserInfoLogic:strNickName strNickName is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
		return nErrorCode;
	end

	-- 检查昵称是否合法
	if not self:CheckNickNameLegal(strNickName) then
		LOG_WARN("UserInfoLogic:strNickName strNickName is illegal");
		nErrorCode = ERROR_CODE.SYSTEM.PARAMTER_ERROR;
	end

	objUser:SetNickName(strNickName);
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 检查昵称的合法性
function UserInfoLogic:CheckNickNameLegal(strNickName)

	local bIsOk = false;
	if not IsString(strNickName) then
		return bIsOk;
	end

	if string.len(strNickName) > STRING_LENGTH_DEF.NICK_NAME then
		LOG_WARN("UserInfoLogic:CheckNickNameLegal strNickName exceeds length:" .. STRING_LENGTH_DEF.NICK_NAME);
		return bIsOk;
	end

	-- to do:检查是否有特殊字符

	-- 检查是否有非法词语
	local bTextLegal = self:CheckTextLegal(strText);
	if not bTextLegal then
		LOG_WARN("UserInfoLogic:CheckNickNameLegal content of strNickName is illegal");
		return bIsOk;
	end

	bIsOk = true; 

	return bIsOk;
end

-- 检查是否有非法输入
function UserInfoLogic:CheckTextLegal(strText)
	return true;
end

-- 绑定手机号码
function UserInfoLogic:BindingPhoneNo(objUser, strPhoneNo)

	local nErrorCode = ERROR_CODE.SYSTEM.UNKNOWN_ERROR;
	if not objUser then
		LOG_ERROR("UserInfoLogic:BindingPhoneNo objUser is nil")
		return nErrorCode;
	end

	--校验手机号码格式
	local bIsOk = self:CheckPhoneNoFormat(strPhoneNo);
	if not bIsOk then
		LOG_WARN("UserInfoLogic:BindingPhoneNo strPhoneNo is illegal");
		nErrorCode = ERROR_CODE.USER_BASE_INFO.PHONE_NO_IS_ILLEGAL;
		return nErrorCode;
	end

	-- 检查是否已经绑定过了
	local strOldPhoneNo = objUser:GetPhoneNo();
	if strOldPhoneNo and string.len(strOldPhoneNo) > 0 then
		LOG_WARN("UserInfoLogic:BindingPhoneNo phone no have been bound");
		nErrorCode = ERROR_CODE.USER_BASE_INFO.HAVE_BEEN_BOUND;
		return nErrorCode;
	end

	objUser:SetPhoneNo(strPhoneNo);
	nErrorCode = ERROR_CODE.SYSTEM.OK;

	return nErrorCode;
end

-- 检验电话号码格式
function UserInfoLogic:CheckPhoneNoFormat(strPhoneNo)
	
	local bIsOk = false;
	if not IsString(strPhoneNo) then
		LOG_WARN("UserInfoLogic:BindingPhoneNo type of strPhoneNo is not string" .. type(strPhoneNo));
		return bIsOk;
	end

	-- 检验号码长度是否为11
	if string.len(strPhoneNo) ~= STRING_LENGTH_DEF.PHONE_NO then
		LOG_WARN("UserInfoLogic:BindingPhoneNo phone no is not equal to 11");
		return bIsOk;
	end

	-- 匹配电话号码格式
	-- to do: 完善匹配的格式,现在匹配不够严格
	local retSub = string.find(strPhoneNo, "[1]%d%d%d%d%d%d%d%d%d%d");
	if retSub then
		bIsOk = true;
	end

	return bIsOk;
end

-- 检查用户ID是否合法
function UserInfoLogic:CheckUserIdLegal(nUserId)
	local bIsOk = false;
	if not IsNumber(nUserId) then
		return bIsOk;
	end

	if nUserId < DATABASE_TABLE_GLOBAL_DEFALUT[DATABASE_TABLE_GLOBAL_FIELD.USER_ID] or nUserId > G_GlobalConfigManager:GetUserGlobalId() then
		return bIsOk;
	end

	bIsOk = true;

	return bIsOk;
end

G_UserInfoLogic = UserInfoLogic:new()
