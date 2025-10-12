local alpha = require 'alpha'

local header = {
	type = 'text',
	val = {
		[[                d8888          888 ]],
		[[               d88888          888 ]],
		[[              d88P888          888 ]],
		[[             d88P 888 888  888 888 ]],
		[[            d88P  888 888  888 888 ]],
		[[           d88P   888 888  888 888 ]],
		[[          d8888888888 Y88b 888 888 ]],
		[[         d88P     888  Y88888 888 ]],
	},
	opts = {
		position = 'center',
		hl = 'Type',
	}
}

local function button(key, icon, text, command)
	return {
		type = 'button',
		val = icon .. '  ' .. text,
		on_press = function()
			vim.cmd(command)
		end,
		opts = {
			position = 'center',
			shortcut = key,
			hl = 'Function',
			hl_shortcut = 'Keyword'
		}
	}
end

local buttons = {
	type = 'group',
	val = {
		button('f', '', 'Find files', 'lua require("fff").find_files()'),
		button('n', '', 'New file', 'enew'),
		button('q', '', 'Quit', 'qa'),
	},
	opts = {
		position = 'center',
		spacing = 2,
	}
}

alpha.setup({
	layout = {
		{ type = 'padding', val = 4 },
		header,
		{ type = 'padding', val = 2 },
		buttons,
		{ type = 'padding', val = 4 },
	},
	opts = {
		margin = 5,
	}
})
