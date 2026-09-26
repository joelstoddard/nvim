-- ================================================================================================
-- TITLE : mini.nvim
-- LINKS :
--   > github : https://github.com/echasnovski/mini.nvim
-- ABOUT : Library of 40+ independent Lua modules.
-- ================================================================================================

return {
	{ "echasnovski/mini.ai", version = "*", opts = {} },
	{ "echasnovski/mini.comment", version = "*", opts = {} },
	{
		"echasnovski/mini.move",
		version = "*",
		config = function()
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
	},
	{ "echasnovski/mini.surround", version = "*", opts = {} },
	{ "echasnovski/mini.cursorword", version = "*", opts = {} },
	{ "echasnovski/mini.indentscope", version = "*", opts = {} },
	{ "echasnovski/mini.pairs", version = "*", opts = {} },
	{ "echasnovski/mini.trailspace", version = "*", opts = {} },
	{ "echasnovski/mini.bufremove", version = "*", opts = {} },
	{ "echasnovski/mini.notify", version = "*", opts = {} },
}
