--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.packages.React)
local WorldContext = require(ReplicatedStorage.react.contexts.WorldContext)
local Components = require(ReplicatedStorage.ecs.components)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local LocalPlayer = Players.LocalPlayer

local useContext = React.useContext
local useEffect = React.useEffect
local e = React.createElement
local useState = React.useState

type GunRecord = MatterTypes.WorldChangeRecord<MatterTypes.ComponentInstance<Components.Gun>>

local function GunCounter(_props)


	local worldContext = useContext(WorldContext)
    local gunData, setGunData = useState(nil :: Components.Gun?)

    local isReloading, setIsReloading = useState(false)

	useEffect(function()
		local loop 
		if worldContext.world then

            local world = worldContext.world
			
			loop = RunService.RenderStepped:Connect(function() 
				local gunFound = false 
				for entityId, gun: Components.Gun, owner in world:query(Components.Gun, Components.Owner) do
					if owner and owner.OwnedBy == LocalPlayer and not gun.Disabled then
						setGunData(gun) -- will only update when component updates (aka new table address)

						local cd = world:get(entityId, Components.Cooldown) :: Components.Cooldown?
						if cd and gun.Reloading then
							setIsReloading(true)
						else
							setIsReloading(false)
						end

						gunFound = true 
					end
				end
				if not gunFound then
					setGunData(nil :: any)
					setIsReloading(false)
				end
			end)
 

		end
        return function() 
            if loop then
				loop:Disconnect()
            end
        end
	end, { worldContext } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.822, 0.877),
		Size = UDim2.fromOffset(261, 75),
	}, {
		selectionName = gunData and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = isReloading and "Reloading..." or string.format(`{gunData.CurrentCapacity}/{gunData.MaxCapacity}`, "%d%d"),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 34,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
		}, {
			uIStroke = e("UIStroke"),
		}),
	})
end

return React.memo(GunCounter)
