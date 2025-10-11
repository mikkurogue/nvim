-- Basic vim settings
local v = vim
v.o.number = true
v.o.relativenumber = true
v.o.signcolumn = "yes"
v.o.wrap = false
v.o.tabstop = 2
v.o.swapfile = false
v.o.winborder = "rounded"
v.o.laststatus = 3
v.o.clipboard = "unnamedplus"
v.o.updatetime = 50 -- milliseconds
-- v.diagnostic.config({ virtual_text = true })

local ns = v.api.nvim_create_namespace("cursor_diagnostics")

local function show_cursor_diagnostics()
	local bufnr = v.api.nvim_get_current_buf()
	local line = v.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
	v.diagnostic.hide(bufnr, ns)
	v.diagnostic.show(ns, bufnr, v.diagnostic.get(bufnr, { lnum = line }), { virtual_text = true })
end

v.api.nvim_create_autocmd({ "CursorHold", "CursorMoved" }, {
	callback = show_cursor_diagnostics
})

-- Basic keymaps vim specific
v.g.mapleader = " "
v.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
v.keymap.set('n', '<leader>w', ':write<CR>')
v.keymap.set('n', '<leader>q', ':quit<CR>')

-- toggle the dashboard
v.keymap.set('n', '<leader>h', ':Dashboard<CR>')

-- Plugins with native package manager
v.pack.add({
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/saghen/blink.cmp", },
	{ src = "https://github.com/zbirenbaum/copilot.lua" },
	{ src = "https://github.com/kdheepak/lazygit.nvim"},
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/echasnovski/mini.files" },
	{ src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = v.version.range('3') },
	-- dependencies for neotree
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	-- optional, but recommended for neotree
	"https://github.com/nvim-tree/nvim-web-devicons",
	{
		src = "https://github.com/folke/trouble.nvim",
	},
	{ src = "https://github.com/nvimdev/dashboard-nvim" }
})

v.keymap.set("n", "<leader>gg", ":LazyGit<CR>")

-- trouble config
v.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { silent = true, noremap = true })

require("mini.pick").setup()
require("mini.pairs").setup()

require("dashboard").setup({
	theme = "doom",
	config = {
		center = {
			{
				icon = ' ',
				icon_hl = 'Title',
				desc = 'Find File           ',
				desc_hl = 'String',
				key = 'f',
				keymap = 'SPC f f',
				key_hl = 'Number',
				key_format = ' %s', -- remove default surrounding `[]`
			},
			{
				icon = ' ',
				desc = 'Check open buffers',
				key = 'b',
				keymap = 'SPC f b',
				key_format = ' %s', -- remove default surrounding `[]`
			},
		},
	}
})

require("neo-tree").setup({
	window = {
		position = "left",
		width = 30,
		mappings = {
			["l"] = "open", -- vim-style open
			["<CR>"] = "open",
			["h"] = "close_node", -- close folder
			["H"] = "close_all_nodes",
			["v"] = "open_vsplit", -- open in vertical split
			["s"] = "open_split", -- open in horizontal split
			["R"] = "refresh", -- refresh tree
			["a"] = "add", -- add file/folder
			["d"] = "delete", -- delete file/folder
			["r"] = "rename", -- rename file/folder
			["y"] = "copy_to_clipboard",
			["x"] = "cut_to_clipboard",
			["p"] = "paste_from_clipboard",
			["q"] = "close_window", -- close neotree
		},
	},

})

v.keymap.set("n", "<leader>e", ":Neotree toggle<CR>")
v.keymap.set("n", "<leader>ff", ":Pick files<CR>")
v.keymap.set("n", "<leader>fb", ":Pick buffers<CR>")

-- COPILOT CORE
require("copilot").setup({
	suggestion = {
		enabled = true, -- enable ghost text
		auto_trigger = true, -- show suggestions automatically
		keymap = {
			accept = "<C-J>", -- accept suggestion
			accept_line = false,
		},
	},
	panel = { enabled = false },
})


-- BLINK CONFIG (load AFTER copilot_cmp.setup)
require("blink.cmp").setup({
	sources = {
		default = {
			'lsp', 'path', 'buffer', 'snippets'
		}
	},
	keymap = {
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = {
			"select_next",
			"fallback",
		},
		["<S-Tab>"] = {
			"select_prev",
			"snippet_backward",
			"fallback",
		},
		["<C-j>"] = {
			"accept",
			function() -- Then try copilot if visible
				local ok, copilot = pcall(require, "copilot.suggestion")
				if ok and copilot.is_visible() then
					copilot.accept()
					return true -- stop the chain
				end
			end,
			"snippet_forward", -- Try snippet forward
			"fallback", -- Finally fallback to default behavior
		},
	},
	completion = {
		list = {
			selection = {
				preselect = true,
				auto_insert = true,
			}
		},
	},
	appearance = {
		use_nvim_cmp_as_default = false,
	},
})

-- LSP configurations
local capabilities = require("blink.cmp").get_lsp_capabilities(v.lsp.protocol.make_client_capabilities())
v.lsp.enable({ "lua_ls", "biome", "rust_analyzer", "vtsls" }, {
	capabilities = capabilities
})

-- format kb wit leader lf
v.keymap.set("n", "<leader>lf", v.lsp.buf.format)

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

-- lsp keymaps
v.keymap.set("n", "gd", v.lsp.buf.definition)
v.keymap.set("n", "gD", v.lsp.buf.declaration)
v.keymap.set("n", "gr", v.lsp.buf.references)
v.keymap.set("n", "gi", v.lsp.buf.implementation)
v.keymap.set("n", "K", v.lsp.buf.hover)
v.keymap.set("n", "<C-k>", v.lsp.buf.signature_help)
v.keymap.set("n", "<leader>rn", v.lsp.buf.rename)
-- both leader ca and la for code action cause i use la but i should use ca
v.keymap.set("n", "<leader>ca", v.lsp.buf.code_action)
v.keymap.set("n", "<leader>la", v.lsp.buf.code_action)

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
