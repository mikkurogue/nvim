local v = vim

-- Basic keymaps vim specific
v.g.mapleader = " "
v.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
v.keymap.set('n', '<leader>w', ':write<CR>')
v.keymap.set('n', '<leader>q', ':quit<CR>')

-- trigger lazygit
v.keymap.set("n", "<leader>gg", ":LazyGit<CR>")
-- mini file picker toggles
v.keymap.set("n", "<leader>fb", ":Pick buffers<CR>")

-- format current buffer
v.keymap.set("n", "<leader>lf", v.lsp.buf.format)


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
