--!strict
local uint64_t = require(script.Parent.uint64_t)
local diy_fp = require(script.Parent.diy_fp)
local ieee = {}

function ieee.normalized_boundaries(sigt0: number, sigt1: number, expt: number): (number, number, number, number, number, number)
	local tmp_sigt0: number, tmp_sigt1: number = uint64_t.add(1, 0, uint64_t.sal(sigt0, sigt1, 1))
	local m_plus_sigt0: number, m_plus_sigt1: number, m_plus_expt: number = diy_fp.normalize(
		-- (sigt << 1) + 1
		tmp_sigt0,
		tmp_sigt1,
		expt - 1
	)
	local m_minus_sigt0: number, m_minus_sigt1: number, m_minus_expt: number
	if sigt0 == 0 and sigt1 == 0 then
		tmp_sigt0, tmp_sigt1 = uint64_t.sal(sigt0, sigt1, 2)
		m_minus_sigt0, m_minus_sigt1 = uint64_t.sub(tmp_sigt0, tmp_sigt1, 1)
		m_minus_expt = expt - 2
	else
		tmp_sigt0, tmp_sigt1 = uint64_t.sal(sigt0, sigt1, 1)
		m_minus_sigt0, m_minus_sigt1 = uint64_t.sub(tmp_sigt0, tmp_sigt1, 1)
		m_minus_expt = expt - 1
	end
	m_minus_sigt0, m_minus_sigt1 = uint64_t.sal(m_minus_sigt0, m_minus_sigt1, m_minus_expt - m_plus_expt)
	return m_minus_sigt0,
		m_minus_sigt1,
				-- minus exponent is assigned to, it's the same as the plus exponent
m_plus_expt,
		
m_plus_sigt0,
		m_plus_sigt1,
		m_plus_expt
end

return ieee
