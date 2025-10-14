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
  { src = "https://github.com/j-hui/fidget.nvim",                     name = "fidget.nvim" },
  { src = "https://github.com/goolord/alpha-nvim" },
  { src = "https://github.com/aznhe21/actions-preview.nvim" },
  { src = "https://github.com/folke/persistence.nvim",                event = "BufReadPre" },
})

-- Add colorschemes
v.pack.add({
  { src = "https://github.com/ellisonleao/gruvbox.nvim" },
  { src = "https://github.com/catppuccin/nvim",              name = "catppuccin" },
  { src = "https://github.com/rose-pine/neovim",             name = "rose-pine" },
  { src = "https://github.com/rebelot/kanagawa.nvim" },
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/AlexvZyl/nordic.nvim" },
  { src = "https://github.com/EdenEast/nightfox.nvim" },
  { src = "https://github.com/tahayvr/matteblack.nvim" },
  { src = "https://github.com/stevedylandev/darkmatter-nvim" },
})

local schemes = {
  "catppuccin",
  "rose-pine",
  "kanagawa",
  "tokyonight",
  "nordic",
  "nightfox",
  "gruvbox",
  "matteblack",
  "darkmatter",
}

-- set colorscheme
v.cmd("colorscheme " .. schemes[7])

require("mini.icons").setup()
require('mini.tabline').setup()
require('mini.pairs').setup()
require('actions-preview').setup()
require('persistence').setup()
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

-- -- the plugin will automatically lazy load
-- v.g.fff = {
--
-- 	lazy_sync = true, -- start syncing only when the picker is open
-- }

v.keymap.set(
  'n',
  'ff',
  function() require('fff').find_files() end,
  { desc = 'FFFind files' }
)

-- Load plugins with custom  config
-- LSP configurations
local capabilities = require("blink.cmp").get_lsp_capabilities(v.lsp.protocol.make_client_capabilities())

local function on_lsp_exit(code, signal, client_id)
  local client = v.lsp.get_client_by_id(client_id)
  if not client then return end

  -- Don't show message on normal exit
  if code == 0 and signal == 0 then
    return
  end

  v.notify(
    string.format("LSP client '%s' crashed. (code: %s, signal: %s)", client.name, tostring(code), tostring(signal)),
    v.log.levels.WARN
  )

  v.notify(string.format("Attempting to restart LSP client: %s", client.name), v.log.levels.INFO)

  local new_client_id = v.lsp.start_client(client.config)
  if new_client_id then
    v.notify(string.format("LSP client '%s' has been restored.", client.name), v.log.levels.INFO)
    -- Re-attach to the current buffer
    v.lsp.buf_attach_client(0, new_client_id)
  else
    v.notify(string.format("Failed to restart LSP client: %s", client.name), v.log.levels.ERROR)
  end
end

v.lsp.enable({ "lua_ls", "biome", "rust_analyzer", "vtsls" }, {
  capabilities = capabilities,
  on_exit = on_lsp_exit,
})
require("configuration.blink-cmp")
require("configuration.conform")
require("configuration.treesitter")
require("configuration.gitsigns")
require("configuration.toggleterm")
require("configuration.fidget")
require("configuration.alpha")
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

-- get current git branch
function _G.GitBranch()
  -- check if gitsigns has set the branch name
  if v.b.gitsigns_head then
    return ' ' .. v.b.gitsigns_head
  end

  -- fallback: try running `git` directly
  local handle = io.popen('git rev-parse --abbrev-ref HEAD 2>/dev/null')
  if not handle then
    return ''
  end
  local branch = handle:read('*l')
  handle:close()
  if branch and branch ~= '' then
    return ' ' .. branch
  end
  return ''
end

-- Example if using statusline
v.o.statusline = "%f %m %r %h %{%v:lua.GitBranch()%} %= %{%v:lua.LspStatus()%} %l:%c"

require("tiny-inline-diagnostic").setup({
  preset = "powerline"
})

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
