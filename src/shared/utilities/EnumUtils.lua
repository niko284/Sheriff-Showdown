--!strict

local EnumUtils = {}

function EnumUtils.IsEnum(EnumList, EnumItem)
	for _, enumList in Enum:GetEnums() do
		if tostring(enumList) == tostring(EnumList) then
			for _, enumItem in pairs(enumList:GetEnumItems()) do
				if enumItem.Name == EnumItem then
					return true
				end
			end
		end
	end
	return false
end

return EnumUtils
