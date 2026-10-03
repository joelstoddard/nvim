-- ================================================================================================
-- TITLE : lualine.nvim
-- LINKS :
--   > github : https://github.com/nvim-lualine/lualine.nvim
-- ABOUT : A blazing fast and easy to configure Neovim statusline written in Lua.
-- ================================================================================================

-- The statusline matches the shell prompt and the tmux bar: grey text on the editor background, and colour only
-- for signals.
local palette = require("plugins.theme")
local text = { fg = palette.muted, bg = palette.bg }
local dim = { fg = palette.dim, bg = palette.bg }

-- mini.diff supplies the counts, so they match the gutter signs. lualine's own git diff can count a whole hunk as
-- changed lines.
local function minidiff_counts()
	local summary = vim.b.minidiff_summary
	if summary then
		return { added = summary.add, modified = summary.change, removed = summary.delete }
	end
end

require("lualine").setup({
	options = {
		icons_enabled = true,
		-- lualine uses the normal colours for a mode with no entry, so the mode never changes the colours.
		theme = { normal = { a = text, b = text, c = text }, inactive = { a = dim, b = dim, c = dim } },
		section_separators = "",
		component_separators = "",
	},
	sections = {
		lualine_b = {
			{ "branch", color = { fg = palette.orange } },
			{
				"diff",
				source = minidiff_counts,
				-- nvim-tree and the shell prompt use these symbols, and git's color.diff uses these colours.
				symbols = { added = "\u{EA7F} ", modified = "\u{EB43} ", removed = "\u{EA81} " },
				diff_color = {
					added = { fg = palette.green },
					modified = { fg = palette.purple },
					removed = { fg = palette.red },
				},
			},
			{
				"diagnostics",
				-- config/lsp.lua sets these glyphs for the sign column, but it loads after this file.
				symbols = { error = "\u{f057} ", warn = "\u{f071} ", info = "\u{f05a} ", hint = "\u{ea61} " },
			},
		},
	},
})
