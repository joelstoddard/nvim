-- Runs inside a headless start of the real config, after vim.pack.add() has cloned any missing plugin.
-- Exits 0 once plugins, parsers and Mason tools are all installed, or 1 with the step that failed.
local languages = require("languages")
local deadline = vim.uv.now() + 15 * 60 * 1000

local function fail(step, detail)
	io.stderr:write(("bootstrap: %s failed: %s\n"):format(step, detail))
	vim.cmd("cquit 1")
end

local function remaining()
	return math.max(deadline - vim.uv.now(), 1000)
end

-- The config schedules install_missing() at startup, and it can run during the parser step's wait. This hook comes
-- first, so it also catches a notice from that early run.
local notice
local notify = vim.notify
vim.notify = function(msg, level, opts)
	if type(msg) == "string" and msg:find("^Mason could not") then
		notice = msg
	end
	return notify(msg, level, opts)
end

-- A failed clone or a config error at startup shows in :messages. vim.pack.get() never lists a failed clone.
local startup = vim.api.nvim_exec2("messages", { output = true }).output
if startup:find("[Ee]rror") then
	fail("plugins", "startup reported: " .. startup)
end
io.stdout:write("bootstrap: plugins ready\n")

-- A second install() stops waiting on the config's startup install after 60 s, so this retries each parser that
-- still fails to load. force is needed because install() counts a language as installed once its queries exist.
local parsers = languages.parsers()
local function missing_parsers()
	local missing = {}
	for _, lang in ipairs(parsers) do
		if not vim.treesitter.language.add(lang) then
			table.insert(missing, lang)
		end
	end
	return missing
end

local ok, done = true, true
local still_missing_parsers = missing_parsers()
for _ = 1, 3 do
	if #still_missing_parsers == 0 then
		break
	end
	ok, done = pcall(function()
		return require("nvim-treesitter").install(still_missing_parsers, { force = true }):wait(remaining())
	end)
	if not ok then
		break
	end
	still_missing_parsers = missing_parsers()
end
if not ok or #still_missing_parsers > 0 then
	local reason = not ok and tostring(done) .. "; " or not done and "timed out; " or ""
	fail("parsers", reason .. "missing: " .. table.concat(still_missing_parsers, ", "))
end
io.stdout:write("bootstrap: parsers ready\n")

local registry = require("mason-registry")
local function missing_packages()
	local missing = {}
	for _, name in ipairs(languages.mason_packages()) do
		local pkg = registry.has_package(name) and registry.get_package(name)
		local receipt = pkg and pkg:is_installed() and vim.fs.joinpath(pkg:get_install_path(), "mason-receipt.json")
		if not (receipt and vim.uv.fs_stat(receipt)) then
			table.insert(missing, name)
		end
	end
	return missing
end

vim.wait(remaining(), function()
	return notice ~= nil or #missing_packages() == 0
end, 1000)
-- Mason warns when it cannot refresh a stale registry, even when every package is installed. So the bootstrap
-- fails only when a package is missing.
local still_missing = missing_packages()
if #still_missing > 0 then
	if notice then
		fail("Mason", notice)
	end
	fail("Mason", "still missing after the timeout: " .. table.concat(still_missing, ", "))
end
io.stdout:write("bootstrap: Mason tools ready\n")
vim.cmd("qall!")
