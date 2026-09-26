vim.loader.enable() -- cache compiled Lua modules for a faster startup
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.plugins")
require("config.lsp")
require("config.terminal")
