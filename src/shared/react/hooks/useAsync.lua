--!strict

--[[
    
MIT License

Copyright (c) 2023 howmanysmall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)
local React = require(Packages.React)

type Promise<T> = any
type UseAsyncState<T> = {
	Exception: unknown?,
	Result: T?,
	Status: typeof(Promise.Status),
}

local function useAsync<T>(promiseOrGetPromise: Promise<T> | () -> Promise<T>, dependencies: { unknown }?)
	local state, setState = React.useState({
		Status = Promise.Status.Started,
	} :: UseAsyncState<T>)

	local exception = state.Exception
	local result = state.Result
	local status = state.Status

	React.useEffect(function()
		if status ~= Promise.Status.Started then
			setState({
				Status = Promise.Status.Started,
			})
		end

		local promise = if type(promiseOrGetPromise) == "function"
			then (promiseOrGetPromise :: () -> Promise<T>)()
			else promiseOrGetPromise

		assert(Promise.is(promise), "Not a promise!")

		promise:andThen(function(value)
			setState({
				Exception = exception,
				Result = value,
				Status = promise:getStatus(),
			})
		end, function(errorMessage)
			setState({
				Exception = errorMessage,
				Result = result,
				Status = promise:getStatus(),
			})
		end)

		return function()
			promise:cancel()
		end
	end, dependencies or {})

	return result, exception, status
end

return useAsync
