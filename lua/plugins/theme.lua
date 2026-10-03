-- ================================================================================================
-- TITLE : ash.nvim
-- ABOUT : a minimal, largely monochromatic colorscheme.
-- LINKS :
--   > github : https://github.com/bjarneo/ash.nvim
-- ================================================================================================

require("ash").setup({
	-- ash draws borders and the colorcolumn in its background colour, which hides them.
	colors = { border = "#626262" },
	highlights = {
		ColorColumn = { bg = "#1c1c1c" },
		-- Indent shading (config/indent.lua): one grey per level, lighter with depth, cycling after four.
		IndentLevel1 = { bg = "#161616" },
		IndentLevel2 = { bg = "#1a1a1a" },
		IndentLevel3 = { bg = "#1e1e1e" },
		IndentLevel4 = { bg = "#222222" },
	},
})
vim.cmd.colorscheme("ash")
