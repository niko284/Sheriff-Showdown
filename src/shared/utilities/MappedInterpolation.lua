--!strict

--[[

	MIT License

	Copyright (c) Meta Platforms, Inc. and affiliates.

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

type extrapolationTypes = "identity" | "clamp"

local function interpolate(
	value: number,
	inputMin: number,
	inputMax: number,
	outputMin: number,
	outputMax: number,
	extrapolateLeft: extrapolationTypes,
	extrapolateRight: extrapolationTypes
)
	local result = value
	-- Extrapolate
	if result < inputMin then
		if extrapolateLeft == "identity" then
			return result
		elseif extrapolateLeft == "clamp" then
			result = inputMin
		else
			assert(false, "Unhandled extrapolation type: " .. extrapolateLeft)
		end
	end
	if result > inputMax then
		if extrapolateRight == "identity" then
			return result
		elseif extrapolateRight == "clamp" then
			result = inputMax
		else
			assert(false, "Unhandled extrapolation type: " .. extrapolateRight)
		end
	end
	if outputMin == outputMax then
		return outputMin
	end
	if inputMin == inputMax then
		if value <= inputMin then
			return outputMin
		else
			return outputMax
		end
	end
	return outputMin + (outputMax - outputMin) * (result - inputMin) / (inputMax - inputMin)
end

local function findRangeIndex(value: number, ranges: { number }): number
	local index
	for i, range in ipairs(ranges) do
		if range >= value then
			index = i
			break
		end
	end
	return index - 1
end

return function(
	value: number,
	inputRange: { number },
	outputRange: { number },
	extrapolateLeft: extrapolationTypes,
	extrapolateRight: extrapolationTypes
)
	local rangeIndex = findRangeIndex(value, inputRange)
	return interpolate(
		value,
		inputRange[rangeIndex],
		inputRange[rangeIndex + 1],
		outputRange[rangeIndex],
		outputRange[rangeIndex + 1],
		extrapolateLeft,
		extrapolateRight
	)
end
