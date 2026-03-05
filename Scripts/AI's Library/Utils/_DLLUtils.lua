_DLLUtils = {}

---@return string | nil
function _DLLUtils.GetCheckedNetworkSvar(svar, listType)
	local svarStr = "network.session.svar" .. svar
	local pContents = GetVarItemStr(svarStr)

	if (pContents == nil or pContents == "") then
		return nil
	end

	for i = 0, GetNetworkListCount(listType) do
		local pItem = GetNetworkListItem(listType, i)

		if (pItem ~= nil) then
			if(pContents == pItem) then
				return pContents
			end
		end
	end

	return nil
end

return _DLLUtils