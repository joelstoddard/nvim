-- ================================================================================================
-- TITLE : plugins
-- ABOUT : installs plugins with the built-in vim.pack, then configures each in list order.
-- LINKS :
--   > vim.pack : :help vim.pack
-- ================================================================================================

-- nvim-tree replaces netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- vim.pack has no build step, so parser updates hang off PackChanged. It must exist before
-- vim.pack.add() to see first installs.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("PackHooks", { clear = true }),
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name ~= "nvim-treesitter" or (kind ~= "install" and kind ~= "update") then
			return
		end
		if not ev.data.active then
			vim.cmd.packadd("nvim-treesitter")
		end
		require("nvim-treesitter").update()
	end,
})

local function gh(repo)
	return "https://github.com/" .. repo
end

vim.pack.add({
	gh("bjarneo/ash.nvim"), -- first, so later highlight tweaks apply on top of it
	{ src = gh("nvim-mini/mini.nvim"), version = vim.version.range("*") },
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- release tags ship a prebuilt fuzzy matcher
	gh("rafamadriz/friendly-snippets"),
	gh("neovim/nvim-lspconfig"),
	gh("mason-org/mason.nvim"),
	gh("creativenull/efmls-configs-nvim"),
	gh("b0o/schemastore.nvim"),
	gh("ibhagwan/fzf-lua"),
	gh("nvim-tree/nvim-tree.lua"),
	gh("nvim-lualine/lualine.nvim"),
	gh("folke/trouble.nvim"),
	gh("folke/which-key.nvim"),
	gh("folke/zen-mode.nvim"),
	gh("uga-rosa/ccc.nvim"),
	gh("prismatic-koi/nvim-sops"),
	gh("christoomey/vim-tmux-navigator"),
})

vim.cmd.colorscheme("ash")

-- mini.nvim : https://github.com/nvim-mini/mini.nvim
-- Set up before lualine, nvim-tree, trouble and fzf-lua so the nvim-web-devicons mock is in place.

-- Leaves an/in to nvim 0.12's treesitter selection. a/i objects still reach the next match (cover_or_next).
require("mini.ai").setup({ mappings = { around_next = "", inside_next = "" } })
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()
require("mini.indentscope").setup()
require("mini.pairs").setup()
require("mini.trailspace").setup()
require("mini.bufremove").setup()
require("mini.notify").setup()

local sessions = require("mini.sessions")
sessions.setup()
-- mini.sessions' own autoread warns on every start without a session, so restore ./Session.vim only if it exists.
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("LocalSessionRead", { clear = true }),
	nested = true,
	once = true,
	callback = function()
		local empty_start = vim.fn.argc() == 0 and vim.api.nvim_buf_line_count(0) == 1 and vim.fn.getline(1) == ""
		if empty_start and sessions.detected[sessions.config.file] then
			sessions.read(sessions.config.file)
		end
	end,
})
vim.keymap.set("n", "<leader>ws", function()
	sessions.write(sessions.config.file)
end, { desc = "Write local session (Session.vim)" })

local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

local diff = require("mini.diff")
diff.setup({ view = { style = "sign", signs = { add = "▎", change = "▎", delete = "▎" } } })
local git = require("mini.git")
git.setup()
-- mini.diff raises an error for buffers without git reference text (untracked, or outside a repo).
local function tracked()
	local data = diff.get_buf_data()
	if data and data.ref_text then
		return true
	end
	vim.notify("(mini.diff) buffer is not tracked by git", vim.log.levels.INFO)
	return false
end
-- ]h and [h come from mini.diff's default mappings.
vim.keymap.set("n", "<leader>hs", function()
	return tracked() and diff.operator("apply") .. "gh" or ""
end, { expr = true, remap = true, desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hp", function()
	if tracked() then
		diff.toggle_overlay()
	end
end, { desc = "Toggle diff overlay" })
vim.keymap.set("n", "<leader>hb", git.show_at_cursor, { desc = "Git blame/show at cursor" })

local move = require("mini.move")
move.setup()
-- mini.move accepts one key for each action. These maps add Alt+Arrow and keep the default Alt+hjkl.
for key, dir in pairs({ Left = "left", Down = "down", Up = "up", Right = "right" }) do
	vim.keymap.set("n", "<M-" .. key .. ">", function()
		move.move_line(dir)
	end, { desc = "Move line " .. dir })
	vim.keymap.set("x", "<M-" .. key .. ">", function()
		move.move_selection(dir)
	end, { desc = "Move selection " .. dir })
end

-- nvim-treesitter : https://github.com/nvim-treesitter/nvim-treesitter
-- language parsers that MUST be installed
local parsers = {
	"bash",
	"css",
	"dockerfile",
	"go",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"typescript",
	"yaml",
	"terraform",
}

local function has_query(lang, name)
	local ok, query = pcall(vim.treesitter.query.get, lang, name)
	return ok and query ~= nil
end

require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match)
		-- A parser without highlight queries (e.g. left behind by the master branch) would blank the buffer.
		if not lang or not vim.treesitter.language.add(lang) or not has_query(lang, "highlights") then
			return
		end
		vim.treesitter.start(args.buf, lang)
		-- nvim-treesitter's indentexpr returns 0 for every line when a language has no indents query.
		if has_query(lang, "indents") then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end

		-- Selection uses nvim 0.12's built-in an/in. They are Lua maps, so these need remap.
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, remap = true, desc = desc })
		end
		map("n", "<CR>", "van", "Start treesitter selection")
		map("x", "<CR>", "an", "Grow treesitter selection")
		map("x", "<S-Tab>", "in", "Shrink treesitter selection")
	end,
})

-- mason.nvim : https://github.com/mason-org/mason.nvim
require("mason").setup({})

-- fzf-lua : https://github.com/ibhagwan/fzf-lua
require("fzf-lua").setup({})
vim.keymap.set("n", "<leader>ff", function()
	require("fzf-lua").files()
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>fg", function()
	require("fzf-lua").live_grep()
end, { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	require("fzf-lua").buffers()
end, { desc = "FZF Buffers" })
vim.keymap.set("n", "<leader>fh", function()
	require("fzf-lua").help_tags()
end, { desc = "FZF Help Tags" })
vim.keymap.set("n", "<leader>fx", function()
	require("fzf-lua").diagnostics_document()
end, { desc = "FZF Diagnostics Document" })
vim.keymap.set("n", "<leader>fX", function()
	require("fzf-lua").diagnostics_workspace()
end, { desc = "FZF Diagnostics Workspace" })

-- nvim-tree.lua : https://github.com/nvim-tree/nvim-tree.lua
-- Remove background color from the NvimTree window (ui fix)
vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])

require("nvim-tree").setup({
	filters = {
		dotfiles = false, -- Show hidden files (dotfiles)
	},
	view = {
		adaptive_size = true,
	},
})

-- lualine.nvim : https://github.com/nvim-lualine/lualine.nvim
require("lualine").setup({
	options = {
		icons_enabled = true,
		section_separators = { left = "", right = "" },
		component_separators = "|",
	},
})

-- trouble.nvim : https://github.com/folke/trouble.nvim
require("trouble").setup({})
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Workspace Diagnostics (Trouble)" })
vim.keymap.set(
	"n",
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
vim.keymap.set(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ desc = "LSP Definitions / references / ... (Trouble)" }
)
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- which-key.nvim : https://github.com/folke/which-key.nvim
require("which-key").setup({})
vim.keymap.set("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })

-- zen-mode.nvim : https://github.com/folke/zen-mode.nvim
require("zen-mode").setup({})

-- ccc.nvim : https://github.com/uga-rosa/ccc.nvim
require("ccc").setup({
	highlighter = {
		auto_enable = true, -- enable highlight automatically
		lsp = true, -- highlight colors from LSP too
	},
	highlight_mode = "virtual", -- small circles with colour next to the declaration
})

-- nvim-sops : https://github.com/prismatic-koi/nvim-sops
local sops_patterns = {
	-- generic "under a secrets directory" or named secrets.env
	"*/secrets.env",
	"*/secrets/*",

	-- ansible vaults
	"*vault*.yml",
	"*vault*.yaml",

	-- sops-explicit naming
	"*.sops",
	"*.sops.yaml",
	"*.sops.yml",
	"*.sops.json",
	"*.sops.env",
	"*.sops.ini",
	"*.sops.toml",

	-- "encrypted" naming convention
	"*.enc.yaml",
	"*.enc.yml",
	"*.enc.json",
	"*.enc.env",

	-- kubernetes/helm secret manifests and values files
	"*secret*.yaml",
	"*secret*.yml",
	"*secret*.json",
	"*secret*.env",

	-- credentials files (gcp service accounts, aws creds, etc.)
	"*credentials*.json",
	"*credentials*.yaml",
	"*credentials*.yml",

	-- terraform tfvars with secrets
	"secrets.tfvars",
	"*.secret.tfvars",
}

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("sops_harden", { clear = true }),
	pattern = sops_patterns,
	callback = function()
		vim.opt_local.undofile = false
	end,
	desc = "Disable persistent undo for sops-encrypted file paths",
})

require("nvim_sops").setup({})
vim.keymap.set("n", "<leader>Sd", "<cmd>SopsDecrypt<cr>", { desc = "Sops: decrypt buffer" })
vim.keymap.set("n", "<leader>Se", "<cmd>SopsEncrypt<cr>", { desc = "Sops: encrypt buffer" })
