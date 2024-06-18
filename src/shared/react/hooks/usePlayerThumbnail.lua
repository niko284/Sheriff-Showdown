--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Hooks = ReplicatedStorage.react.hooks

local Promise = require(Packages.Promise)
local useAsync = require(Hooks.useAsync)

local getUserThumbnailAsync = Promise.promisify(Players.GetUserThumbnailAsync)

local QUESTION_MARK_IMAGE = "rbxassetid://13062221114"
local FAILED_IMAGE = "rbxassetid://13062184161"

-- // Hook \\

local function usePlayerThumbnail(
	playerId: number,
	thumbnailType: Enum.ThumbnailType,
	thumbnailSize: Enum.ThumbnailSize
)
	local playerThumbnail: string?, _err, status = useAsync(
		Promise.retryWithDelay(function()
			return getUserThumbnailAsync(Players, playerId, thumbnailType, thumbnailSize)
		end, 10, 3),
		{ playerId, thumbnailType, thumbnailSize } :: { any }
	) -- 10 retries, 3 seconds between retries

	if status == Promise.Status.Started then
		-- Promise is still running, return a question mark to indicate that the thumbnail is loading.
		return QUESTION_MARK_IMAGE, status
	elseif status == Promise.Status.Rejected then
		-- Promise failed, return a x mark to indicate that the thumbnail failed to load.
		return FAILED_IMAGE, status
	elseif status == Promise.Status.Resolved and playerThumbnail then
		-- Promise succeeded, return the thumbnail.
		return playerThumbnail, status
	else
		-- Promise is in an unknown state (maybe cancelled from the useAsync useEffect), return a question mark to indicate that the thumbnail is loading.
		-- This is probably not needed since cancelled promises are started again by the useAsync hook, but it's here just in case.
		return QUESTION_MARK_IMAGE, status
	end
end

return usePlayerThumbnail
