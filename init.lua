-- Basic vim settings

require("core.opts")
require("core.keymaps")

local v = vim

-- Plugins with native package manager
v.pack.add({
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/saghen/blink.cmp", },
	{ src = "https://github.com/zbirenbaum/copilot.lua" },
	{ src = "https://github.com/kdheepak/lazygit.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/echasnovski/mini.files" },
	{ src = "https://github.com/folke/trouble.nvim" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
	{ src = "https://github.com/dmtrKovalenko/fff.nvim" },
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/nvim-mini/mini.icons" }
})

require("mini.icons").setup()

require("configuration.snacks")
local Snacks = require("snacks")
vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer()
end)
vim.keymap.set("n", "<leader>h", function() Snacks.dashboard() end)

v.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local spec = ev.data.spec
		if spec and spec.name == "fff.nvim" and ev.data.kind == "install" or ev.data.kind == "update" then
			local fff_path = v.fn.stdpath("data") .. "/site/pack/core/opt/fff.nvim"
			v.fn.jobstart({ "cargo", "build", "--release" }, {
				cwd = fff_path,
				on_exit = function(_, code)
					if code == 0 then
						v.notify("Cargo build finished successfully in " .. fff_path,
							v.log.levels.INFO)
					else
						v.notify("Cargo build failed with exit code " .. code, v.log.levels
							.ERROR)
					end
				end,
			})
		end
	end,
})

-- the plugin will automatically lazy load
v.g.fff = {
	lazy_sync = true, -- start syncing only when the picker is open
	debug = {
		enabled = true,
		show_scores = true,
	},
}

v.keymap.set(
	'n',
	'ff',
	function() require('fff').find_files() end,
	{ desc = 'FFFind files' }
)

-- Load plugins with custom  config
require("configuration.blink-cmp")
require("configuration.conform")

require("mini.pick").setup()
require("mini.pairs").setup()
-- Diagnostics UI
require("tiny-inline-diagnostic").setup({
	preset = "powerline"
})

v.keymap.set("n", "<leader>xx", function() require("trouble").toggle("diagnostics") end,
	{ desc = "Toggle Trouble diagnostics" })

-- LSP configurations
local capabilities = require("blink.cmp").get_lsp_capabilities(v.lsp.protocol.make_client_capabilities())
v.lsp.enable({ "lua_ls", "biome", "rust_analyzer", "vtsls" }, {
	capabilities = capabilities
})

-- Format on save with lsp configuration
local fmt_grp = v.api.nvim_create_augroup("LspFormatOnSave", { clear = true })

-- This function runs when an LSP client attaches to a buffer
v.api.nvim_create_autocmd("LspAttach", {
	group = fmt_grp,
	callback = function(args)
		local bufnr = args.buf
		local client_id = args.data.client_id
		local client = v.lsp.get_client_by_id(client_id)
		if not client then
			return
		end

		if client.server_capabilities.documentFormattingProvider or client.server_capabilities.documentRangeFormattingProvider then
			v.api.nvim_clear_autocmds({ group = fmt_grp, buffer = bufnr })
			v.api.nvim_create_autocmd("BufWritePre", {
				group = fmt_grp,
				buffer = bufnr,
				callback = function()
					v.lsp.buf.format({
						bufnr = bufnr,
						async = false,
						timeout_ms = 2000,
					})
				end,
				desc = "LSP format on save",
			})
		end
	end,
})

-- Show lsp progress in command line
v.api.nvim_create_autocmd("LspProgress", {
	callback = function(args)
		if args.data and args.data.params then
			local msg = args.data.params.value
			if msg and msg.kind == "end" then
				print("rust-analyzer: " .. (msg.message or "done"))
			end
		end
	end,
})
-- show lsp that is attached to buffer
function _G.LspStatus()
	local bufnr = v.api.nvim_get_current_buf()
	local clients = v.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		return ''
	end
	local names = {}
	for _, c in ipairs(clients) do
		table.insert(names, c.name)
	end
	return '  ' .. table.concat(names, ', ')
end

-- Example if using statusline
v.o.statusline = "%f %m %r %h %= %{%v:lua.LspStatus()%} %l:%c"

-- set colorscheme
v.cmd("colorscheme gruvbox")
