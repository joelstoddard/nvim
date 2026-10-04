-- The bootstrap's plugin sync (tests/sync.lua): offline first, then online for plugins still off the lockfile.
local new_set, expect = MiniTest.new_set, MiniTest.expect
local sync = dofile("tests/sync.lua")

local T = new_set()

-- A fake vim.pack.update records each call. offs lists what each off() call returns, in order.
local function fake(offs)
	local calls, n = {}, 0
	local function update(names, opts)
		table.insert(calls, { names = names or "all", offline = opts.offline == true })
	end
	local function off()
		n = n + 1
		return offs[n]
	end
	return update, off, calls
end

T["stays offline when every plugin reaches the lockfile"] = function()
	local update, off, calls = fake({ {} })
	local ok, _, still_off = sync(update, off)
	expect.equality({ ok, still_off, calls }, { true, {}, { { names = "all", offline = true } } })
end

T["goes online only for plugins the offline sync could not move"] = function()
	local update, off, calls = fake({ { "b" }, {} })
	local ok, _, still_off = sync(update, off)
	expect.equality({ ok, still_off, calls[2] }, { true, {}, { names = { "b" }, offline = false } })
end

return T
