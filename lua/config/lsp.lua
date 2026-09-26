-- ================================================================================================
-- TITLE : LSP
-- ABOUT : diagnostics, keymaps on attach, server configs and efm linters/formatters.
-- LINKS :
--   > nvim-lspconfig     : https://github.com/neovim/nvim-lspconfig
--   > efm-langserver     : https://github.com/mattn/efm-langserver
--   > efmls-configs-nvim : https://github.com/creativenull/efmls-configs-nvim
-- ================================================================================================

-- Diagnostics -----------------------------------------------------------------------------------
local diagnostic_signs = {
	Error = "\u{f057} ",
	Warn = "\u{f071} ",
	Hint = "\u{ea61}",
	Info = "\u{f05a}",
}

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
})

-- Keymaps on attach -----------------------------------------------------------------------------
-- vim.diagnostic.jump() only moves the cursor, so show the diagnostic it lands on.
local function show_diagnostic()
	vim.diagnostic.open_float({ scope = "cursor", focus = false })
end

local function on_attach(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if not client then
		return
	end
	local bufnr = event.buf
	local keymap = vim.keymap.set
	local opts = {
		noremap = true, -- prevent recursive mapping
		silent = true, -- don't print the command to the cli
		buffer = bufnr, -- restrict the keymap to the local buffer number
	}

	-- native neovim keymaps
	keymap("n", "<leader>gd", function()
		require("fzf-lua").lsp_definitions()
	end, opts) -- goto definition (picker, or jump when there is one result)
	keymap("n", "<leader>gD", vim.lsp.buf.definition, opts) -- goto definition
	keymap("n", "<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, opts) -- goto definition in split
	keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Code actions
	keymap("n", "<leader>rn", vim.lsp.buf.rename, opts) -- Rename symbol
	keymap("n", "<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts) -- Line diagnostics (float)
	keymap("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts) -- Cursor diagnostics
	keymap("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1, on_jump = show_diagnostic })
	end, opts) -- previous diagnostic
	keymap("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1, on_jump = show_diagnostic })
	end, opts) -- next diagnostic
	keymap("n", "K", vim.lsp.buf.hover, opts) -- hover documentation

	-- fzf-lua keymaps
	keymap("n", "<leader>fd", "<cmd>FzfLua lsp_finder<CR>", opts) -- LSP Finder (definition + references)
	keymap("n", "<leader>fr", "<cmd>FzfLua lsp_references<CR>", opts) -- Show all references to the symbol under the cursor
	keymap("n", "<leader>ft", "<cmd>FzfLua lsp_typedefs<CR>", opts) -- Jump to the type definition of the symbol under the cursor
	keymap("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", opts) -- List all symbols (functions, classes, etc.) in the current file
	keymap("n", "<leader>fw", "<cmd>FzfLua lsp_workspace_symbols<CR>", opts) -- Search for any symbol across the entire project/workspace
	keymap("n", "<leader>fi", "<cmd>FzfLua lsp_implementations<CR>", opts) -- Go to implementation

	-- Order Imports (if supported by the client LSP)
	if client:supports_method("textDocument/codeAction", bufnr) then
		keymap("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = {
					only = { "source.organizeImports" },
					diagnostics = {},
				},
				apply = true,
				bufnr = bufnr,
			})
			-- format after changing import order
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50) -- slight delay to allow for the import order to go first
		end, opts)
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspMappings", {}),
	callback = on_attach,
})

-- Servers ---------------------------------------------------------------------------------------
-- blink.cmp registers its completion capabilities on vim.lsp.config("*"), so no server repeats them.
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					vim.fn.expand("$VIMRUNTIME/lua"),
					vim.fn.expand("$XDG_CONFIG_HOME") .. "/nvim/lua",
				},
			},
		},
	},
})

vim.lsp.config("pyright", {
	settings = {
		pyright = {
			disableOrganizeImports = false,
			analysis = {
				useLibraryCodeForTypes = true,
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				autoImportCompletions = true,
			},
		},
	},
})

vim.lsp.config("gopls", { filetypes = { "go" } })
vim.lsp.config("jsonls", { filetypes = { "json", "jsonc" } })
vim.lsp.config("ts_ls", {
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
	settings = {
		typescript = {
			indentStyle = "space",
			indentSize = 2,
		},
	},
})
vim.lsp.config("bashls", { filetypes = { "sh", "bash", "zsh" } })
vim.lsp.config("dockerls", { filetypes = { "dockerfile" } })
vim.lsp.config("yamlls", {
	settings = {
		yaml = {
			schemastore = {
				enable = false,
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
			validate = true,
			format = {
				enable = true,
			},
		},
	},
	filetypes = { "yaml" },
})
vim.lsp.config("tailwindcss", {
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
})

-- Linters & formatters (efm) --------------------------------------------------------------------
local luacheck = require("efmls-configs.linters.luacheck") -- lua linter
local stylua = require("efmls-configs.formatters.stylua") -- lua formatter
local flake8 = require("efmls-configs.linters.flake8") -- python linter
local black = require("efmls-configs.formatters.black") -- python formatter
local go_revive = require("efmls-configs.linters.go_revive") -- go linter
local gofumpt = require("efmls-configs.formatters.gofumpt") -- go formatter
local prettier_d = require("efmls-configs.formatters.prettier_d") -- ts/js/solidity/json/docker/html/css/react/svelte/vue formatter
local eslint_d = require("efmls-configs.linters.eslint_d") -- ts/js/solidity/json/react/svelte/vue linter
local fixjson = require("efmls-configs.formatters.fixjson") -- json formatter
local shellcheck = require("efmls-configs.linters.shellcheck") -- bash linter
local shfmt = require("efmls-configs.formatters.shfmt") -- bash formatter
local hadolint = require("efmls-configs.linters.hadolint") -- docker linter
local cpplint = require("efmls-configs.linters.cpplint") -- c/cpp linter
local clangformat = require("efmls-configs.formatters.clang_format") -- c/cpp formatter
local solhint = require("efmls-configs.linters.solhint") -- solidity linter

vim.lsp.config("efm", {
	filetypes = {
		"sh",
		"css",
		"docker",
		"go",
		"html",
		"javascript",
		"javascriptreact",
		"json",
		"jsonc",
		"lua",
		"markdown",
		"python",
		"typescript",
		"typescriptreact",
		"yaml",
		"terraform",
	},
	init_options = {
		documentFormatting = true,
		documentRangeFormatting = true,
		hover = true,
		documentSymbol = true,
		codeAction = true,
		completion = true,
	},
	settings = {
		languages = {
			c = { clangformat, cpplint },
			cpp = { clangformat, cpplint },
			css = { prettier_d },
			docker = { hadolint, prettier_d },
			go = { gofumpt, go_revive },
			html = { prettier_d },
			javascript = { eslint_d, prettier_d },
			javascriptreact = { eslint_d, prettier_d },
			json = { eslint_d, fixjson },
			jsonc = { eslint_d, fixjson },
			lua = { luacheck, stylua },
			markdown = { prettier_d },
			python = { flake8, black },
			sh = { shellcheck, shfmt },
			solidity = { solhint, prettier_d },
			svelte = { eslint_d, prettier_d },
			typescript = { eslint_d, prettier_d },
			typescriptreact = { eslint_d, prettier_d },
			vue = { eslint_d, prettier_d },
		},
	},
})

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"gopls",
	"jsonls",
	"ts_ls",
	"bashls",
	"dockerls",
	"yamlls",
	"tailwindcss",
	"efm",
})
