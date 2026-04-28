--!strict

local function updateInputs(_world: any, state: any)
	state.actions:update(state.inputState, state.inputMap)
	state.inputState:clear()
end

return updateInputs
