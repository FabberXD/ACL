local cleanup = {}

local metatable = {

	__call = function(self, t)
		if self == nil or t == nil then return end

		local next = next
		
		-- 0: not processed
		-- 1: cleaning metatable
		-- 2: cleaning table

		local stack = {{t = t, m = nil, step = 0, k = nil, cleaningChildren = false}}
		local cursor = #stack
		local current = stack[cursor]
		local meta
		local k
		local m
		local t

		while current ~= nil do
			
			if current.step == 0 then
				-- clean metatable
				meta = getmetatable(current.t)

				if meta ~= nil then 
					current.m = meta
					current.step = 1
					-- goto continue
				else
					current.step = 2
					-- goto continue
				end

			elseif current.step == 1 then 
				-- cleaning metatable
				m = current.m

				if current.k == nil then
					k = next(m)
				else
					-- continue after dealing with children
					k = current.k 
				end

				while k ~= nil do
					if type(m[k]) == "table" then
						if current.cleaningChildren then
							current.cleaningChildren = false
							m[k] = nil
							k = next(m, k)
						else
							for _, entry in ipairs(stack) do
								if entry.t == m[k] or entry.m == m[k] then
									-- print("found cycle ref (1)")
									m[k] = nil
									k = next(m, k)
									goto continue
								end
							end
							current.k = k
							current.cleaningChildren = true
							table.insert(stack, {t = m[k], m = nil, step = 0, k = nil, cleaningChildren = false})
							cursor = cursor + 1
							current = stack[cursor]
							goto continue
						end
					else
						m[k] = nil
						k = next(m, k)
					end
				end

				current.k = nil
				current.step = 2			

			elseif current.step == 2 then 
				-- cleaning table
				t = current.t

				if current.k == nil then
					k = next(t)
				else
					-- continue after dealing with children
					k = current.k
				end

				while k ~= nil do
					if type(t[k]) == "table" then
						if current.cleaningChildren then
							current.cleaningChildren = false
							t[k] = nil
							k = next(t, k)
						else
							for _, entry in ipairs(stack) do
								if entry.t == t[k] or entry.m == t[k] then
									-- print("found cycle ref (2)")
									t[k] = nil
									k = next(t, k)
									goto continue
								end
							end
							current.k = k
							current.cleaningChildren = true
							table.insert(stack, {t = t[k], m = nil, step = 0, k = nil, cleaningChildren = false})
							cursor = cursor + 1
							current = stack[cursor]
							goto continue
						end
					else
						t[k] = nil
						k = next(t, k)
					end
				end

				cursor = cursor - 1
				if cursor == 0 then
					current = nil
				else
					current = stack[cursor]
				end
			end

			::continue::
		end
	end
}

setmetatable(cleanup, metatable)

return cleanup