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
