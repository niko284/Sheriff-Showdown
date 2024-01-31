-- Enum Utils
-- May 20th, 2022
-- Nick

-- // Variables \\

-- // Util Variables \\

local EnumUtils = {}

-- // Functions \\

function EnumUtils.IsEnum(EnumList, EnumItem)
	-- selene: allow(incorrect_standard_library_use)
	for _, enumList in pairs(Enum:GetEnums()) do
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
