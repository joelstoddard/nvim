-- ================================================================================================
-- TITLE : nvim-lspconfig
-- ABOUT : Quickstart configurations for the built-in Neovim LSP client.
-- LINKS :
--   > github                  : https://github.com/neovim/nvim-lspconfig
--   > mason.nvim (dep)        : https://github.com/mason-org/mason.nvim
--   > efmls-configs-nvim (dep): https://github.com/creativenull/efmls-configs-nvim
--   > blink.cmp (dep)         : https://github.com/saghen/blink.cmp
-- ================================================================================================

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} }, -- LSP/DAP/Linter installer & manager
		"creativenull/efmls-configs-nvim", -- Preconfigured EFM Language Server setups
		"saghen/blink.cmp", -- completion capabilities for every server
	},
	config = function()
		require("utils.diagnostics").setup()
		require("servers")
	end,
}
