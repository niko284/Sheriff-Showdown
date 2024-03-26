--- Version 3.0.2
--[=[
	--- API
	It's broadly based around a subset of ICU's NumberFormatter with many features removed. There are differences (like you're able to define your own suffixes/abbreviations `Notation.compactWithSuffixThousands({ "K", "M", "B", "T", ... })` in this module) but the majority are similar.

	---- NumberFormatter
	The class to format the numbers, located in `FormatNumber.NumberFormatter`.

	----- Methods
	`string` NumberFormatter:Format(number value)
	The number to format, it could be any Luau number. It accounts for negative numbers, infinities, and NaNs. It returns `string` instead of `FormattedNumber` to simplify the implemention of module.

	------ Settings chain methods
	These are methods that returns NumberFormatter with the specific settings changed. Calling the methods doesn't change the NumberFormatter object itself so you have to use NumberFormatter that it returned.

	`NumberFormatter` NumberFormatter:Notation(FormatNumber.Notation notation)
	See Notation.
	`NumberFormatter` NumberFormatter:Precision(FormatNumber.Precision precision)
	See Precision.
	`NumberFormatter` NumberFormatter:RoundingMode(FormatNumber.RoundingMode roundingMode)
	See FormatNumber.RoundingMode enum.
	`NumberFormatter` NumberFormatter:Grouping(FormatNumber.GroupingStrategy strategy)
	See FormatNumber.GroupingStrategy enum.
	`NumberFormatter` NumberFormatter:IntegerWidth(FormatNumber.IntegerWidth strategy)
	See IntegerWidth.
	`NumberFormatter` NumberFormatter:Sign(FormatNumber.SignDisplay style)
	See FormatNumber.SignDisplay enum.

	---- Notation
	These specify how the number is rendered, located in `FormatNumber.Notation`.

	----- Static methods
	`ScientificNotation` Notation.scientific()
	`ScientificNotation` Notation.engineering()
	Scientific notation and the engineering version of it respectively. Uses `E` as the exponent separator but I might add an option to change it in the future.

	`Notation` Notation.compactWithSuffixThousands({ string } suffixTable)
	Basically abbreviations with suffix appended, scaling by every thousands as the suffix changes.

	`Notation` Notation.simple()
	The standard formatting without any scaling. The default.

	----- ScientificNotation (methods)
	`ScientificNotation` ScientificNotation:WithMinExponentDigits(number minExponetDigits)
	The minimum, padding with zeroes if necessary.

	`ScientificNotation` ScientificNotation:WithExponentSignDisplay(FormatNumber.SignDisplay exponentSignDisplay)
	See FormatNumber.SignDisplay enum.

	---- Precision
	These are precision settings and changes to what places/figures the number rounds to, located in `FormatNumber.Precision`. The default is `Precision.integer():WithMinDigits(2)` for abbreviations and `Precision.maxFraction(6)` otherwise.
	NOTE: Due to how it internally converts from double to decimal it'll round to certain significant digits depending on the number first, regardless what precision you set, so `Precision.maxSignificantDigits(17)` probably acts like `Precision.unlimited()` for doubles. This is an implementation detail and I won't explain how it works here.

	----- Static methods
	`FractionPrecision` Precision.integer()
	Rounds the number to the nearest integer

	`FractionPrecision` Precision.minFraction(number minFractionDigits)
	`FractionPrecision` Precision.maxFraction(number maxFractionDigits)
	`FractionPrecision` Precision.minMaxFraction(number minFractionDigits, number maxFractionDigits)
	`FractionPrecision` Precision.fixedFraction(number fixedFractionDigits)
	Rounds the number to a certain fractional digits (or decimal places), min is the minimum fractional (decimal) digits to show, max is the fractional digits (decimal places) to round, fixed refers to both min and max.

	`Precision` Precision.minSignificantDigits(number minSignificantDigits)
	`Precision` Precision.maxSignificantDigits(number maxSignificantDigits)
	`Precision` Precision.minMaxSignificantDigits(number minSignificantDigits, number maxSignificantDigits)
	`Precision` Precision.fixedFraction(number fixedSignificantDigits)
	Round the number to a certain significant digits; min, max, and fixed are specified above

	`Precision` Precision.unlimited()
	Show all available digits to its full precision.

	----- FractionPrecision (methods)
	These are subclass of `Precision` with more options for the fractional (decimal) digits
	`Precision` FractionPrecision:WithMinDigits(number minSignificantDigits)
	Round to the decimal places specified  by the FractionPrecision object but keep at least the amount of significant digit specified by the argument.

	`Precision` FractionPrecision:WithMaxDigits(number maxSignificantDigits)
	Round to the decimal places specified  by the FractionPrecision object but don't keep any more the amount of significant digit specified by the argument.

	---- IntegerWidth

	----- Static methods
	`IntegerWidth` IntegerWidth.zeroFillTo(number minInt)
	Zero fill numbers at the integer part of the number to guarantee at least certain digit in the integer part of the number.

	----- Methods
	`IntegerWidth` IntegerWidth:TruncateAt(number maxInt)
	Truncates the integer part of the number to certain digits

	---- Enums
	The associated numbers in all these enums are an implementation detail, please do not rely on them so instead of using `0`, use `FormatNumber.SignDisplay.AUTO`.

	----- FormatNumber.GroupingStrategy
	This determines how the grouping separator (comma) is inserted - integer part only. There are three options.
	- OFF - no grouping
	- MIN2 - grouping only on 5 digits or above (default for compact notation)
	- ON_ALIGNED - always group the value (default unless it's compact notation)

	MIN2 is the default for abbreviations/compact notation because it just is and is a convention. It's been this way, in all versions of International (though hidden internally before 2.1), starting at ICU 59, and starting at version 2 of the module.

	----- FormatNumber.SignDisplay
	This determines how you display the plus sign (`+`) and the minus sign (`-`):
	- AUTO - Displays the minus sign only if the value is negative (that includes -0 and -NaN) (default)
	- ALWAYS - Displays the plus/minus sign on all values
	- NEVER - Don't display the plus/minus sign
	- EXCEPT_ZERO - Display the plus/minus sign on all values except zero and NaN
	- NEGATIVE - Display the minus sign only if the value is negative but do not display the minus sign on -0 and -NaN

	This doesn't support accounting sign display yet but I might consider it later.

	----- FormatNumber.RoundingMode
	This determines the rounding mode. We currently only have three mode but I might add more if there are uses for others.
	- HALF_EVEN - Round it to the nearest even if it's in the midpoint, round it up if it's above the midpoint and down otherwise (default unless it's compact or scientific/engineering notation)
	- HALF_UP - Round it up if it's in the midpoint or above, down otherwise (most familiar)
	- DOWN - Truncate the values (default for compact and scientific/engineering notation)

	DOWN is the default for compact and scientific/engineering notation because this is actually needed as it'd feel wrong to format 1999 as `2K` instead of `1.9K`.
]=]
--

--[=[
	--- LICENSE
	FormatNumber
	Version 3.0.2
	BSD 2-Clause Licence
	Copyright 2021 - Blockzez (devforum.roblox.com/u/Blockzez and github.com/Blockzez)
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	1. Redistributions of source code must retain the above copyright notice, this
	   list of conditions and the following disclaimer.
	
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]=]
local FormatNumber = {}
local NumberFormatter = require(script.NumberFormatter)

FormatNumber.Notation = require(script.Notation)
FormatNumber.Precision = require(script.Precision)
FormatNumber.IntegerWidth = require(script.IntegerWidth)
FormatNumber.NumberFormatter = NumberFormatter

FormatNumber.RoundingMode = {
	HALF_EVEN = 0,
	HALF_UP = 1,
	DOWN = 2,
}

FormatNumber.GroupingStrategy = {
	OFF = 0,
	MIN2 = 1,
	AUTO = 2,
}

FormatNumber.SignDisplay = {
	AUTO = 0,
	ALWAYS = 1,
	NEVER = 2,
	EXCEPT_ZERO = 3,
	NEGATIVE = 4,
}

export type Notation = NumberFormatter.Notation
export type Precision = NumberFormatter.Precision
export type IntegerWidth = NumberFormatter.IntegerWidth
export type NumberFormatter = NumberFormatter.NumberFormatter

return FormatNumber
