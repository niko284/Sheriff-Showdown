--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type SeparatorProps = Types.FrameProps & { image: string }

local function Separator(props: SeparatorProps)
	return e("ImageLabel", {
		Image = props.image or "rbxassetid://17884887691",
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
	})
end

return React.memo(Separator)
