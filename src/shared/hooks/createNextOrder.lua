-- Create Next Order
-- July 20th, 2023
-- Nick (credits to Kampfkarren for original code).

-- // Function \\

local function createNextOrder()
	local layoutOrder = 0

	return function()
		layoutOrder += 1
		return layoutOrder
	end
end

return createNextOrder
