--!strict

local React = require("@packages/React")
local Types = require("@constants/Types")

local e = React.createElement

type SeparatorProps = Types.FrameProps & { image: string? }

local function Separator(props: SeparatorProps)
	return e("ImageLabel", {
		Image = props.image or "rbxassetid://17884887691",
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
	})
end

return React.memo(Separator)
