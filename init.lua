-- Basic vim settings

require("core.opts")


local v = vim

-- Plugins with native package manager
v.pack.add({
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
	{ src = "https://github.com/nvim-mini/mini.icons" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-mini/mini.tabline" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/akinsho/toggleterm.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

-- Add colorschemes
v.pack.add({
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/catppuccin/nvim",         name = "catppuccin" },
	{ src = "https://github.com/rose-pine/neovim",        name = "rose-pine" },
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/AlexvZyl/nordic.nvim" },
	{ src = "https://github.com/EdenEast/nightfox.nvim" },
})

local schemes = {
	"catppuccin",
	"rose-pine",
	"kanagawa",
	"tokyonight",
	"nordic",
	"nightfox",
	"gruvbox",
}

-- set colorscheme
v.cmd("colorscheme " .. schemes[7])

require("mini.icons").setup()
require('mini.tabline').setup()
require("oil").setup({
	default_file_explorer = true,
	keymaps = {
		["q"] = "actions.close",
		["esc"] = "actions.close",
		["<leader>e"] = "actions.close",
		["<BS>"] = "actions.parent",
		["<leader><BS>"] = "actions.parent",
		["h"] = "actions.parent",
		["l"] = "actions.select",
		["<CR>"] = "actions.select",
		["<leader>r"] = "actions.refresh",
		["gr"] = "actions.refresh",
		["<leader>."] = "actions.toggle_hidden",
	},
	view_options = {
		show_hidden = true,
		highlight_opened_files = "name"
	},
	lsp_file_methods = {
		enabled = true,
		timeout_ms = 1000,
	},
	columns = {
		"icon",
	},
	float = {
		padding = 2,
		border = "rounded",
		max_width = 0.5,
		max_height = 0.5,
	},
	open = "float",
})

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
require("configuration.treesitter")
require("configuration.gitsigns")
require("configuration.toggleterm")

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




v.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local bufnr = v.api.nvim_get_current_buf()
		local bufname = v.api.nvim_buf_get_name(bufnr)
		local buftype = v.api.nvim_buf_get_option(bufnr, "buftype")
		if bufname ~= "" and buftype == "" then
			for _, b in ipairs(v.api.nvim_list_bufs()) do
				if v.api.nvim_buf_is_loaded(b)
						and v.bo[b].buflisted
						and b ~= bufnr
						and v.api.nvim_buf_get_name(b) == "" then
					v.cmd("bd " .. b)
				end
			end
		end
	end,
})



require("core.keymaps")
