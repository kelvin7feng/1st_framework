UserData = class()

function UserData:ctor(nUserId, tbGameData)

	self.m_bIsDirty = false;
	self.m_nUserId = nUserId;
	self.m_tbGameData = tbGameData;

	self.mata_table = {}
	function self.mata_table.__newindex()
		LOG_ERROR("UserData read only...")
		return ;
	end
end

function UserData:GetUserId()
	return self.m_nUserId;
end

function UserData:GetGameData()
	return self.m_tbGameData;
end

function UserData:Print()
	LOG_TABLE(self.m_tbGameData);
end