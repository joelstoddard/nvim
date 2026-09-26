-- ================================================================================================
-- TITLE : mini.nvim
-- LINKS :
--   > github : https://github.com/nvim-mini/mini.nvim
-- ABOUT : Library of 40+ independent Lua modules.
-- ================================================================================================

return {
	"nvim-mini/mini.nvim",
	version = "*",
	lazy = false,
	-- Loads after the colorscheme (1000) and before plugins that ask for nvim-web-devicons.
	priority = 900,
	config = function()
		require("mini.ai").setup()
		require("mini.comment").setup()
		require("mini.surround").setup()
		require("mini.cursorword").setup()
		require("mini.indentscope").setup()
		require("mini.pairs").setup()
		require("mini.trailspace").setup()
		require("mini.bufremove").setup()
		require("mini.notify").setup()

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
	end,
}
