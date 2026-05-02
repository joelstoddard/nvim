-- ================================================================================================
-- TITLE : nvim-sops
-- ABOUT : Encrypt and decrypt sops files in-buffer. Wraps the `sops` CLI; works with any recipient
--         type (age, AWS KMS, GCP, etc.) using metadata embedded in the file. No `.sops.yaml`
--         required for editing.
-- LINKS :
--   > github : https://github.com/prismatic-koi/nvim-sops
-- ================================================================================================

local sops_patterns = {
	"*/secrets.env",
	"*/secrets/*",
	"*vault*.yml",
	"*vault*.yaml",
	"*.sops.yaml",
	"*.sops.yml",
	"*.sops.json",
}

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("sops_harden", { clear = true }),
	pattern = sops_patterns,
	callback = function()
		vim.opt_local.undofile = false
	end,
	desc = "Disable persistent undo for sops-encrypted file paths",
})

return {
	"prismatic-koi/nvim-sops",
	event = { "BufReadPost" },
	opts = {},
	keys = {
		{ "<leader>Sd", "<cmd>SopsDecrypt<cr>", desc = "Sops: decrypt buffer" },
		{ "<leader>Se", "<cmd>SopsEncrypt<cr>", desc = "Sops: encrypt buffer" },
	},
}
