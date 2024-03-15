-- [OPTIONS.UI] --

-- show the number column
vim.opt.number = true
vim.opt.relativenumber = true

-- always show the sign column
vim.opt.signcolumn = "yes"

-- do not wrap long lines
vim.opt.wrap = false

-- keep the cursor centered vertically
vim.opt.scrolloff = 999

-- sane window splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- highlight the cursor line
vim.opt.cursorline = true

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.highlight.on_yank() end,
})

-- enable cursor blinking
vim.opt.guicursor:append("a:blinkon500")

-- hide the command line
vim.opt.cmdheight = 0

-- [OPTIONS.EDITOR] --

-- always use the system clipboard
vim.opt.clipboard = "unnamedplus"

-- expand tabs to 4 spaces
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- ignore case in search patterns
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function() vim.lsp.buf.format() end,
})

-- [KEYMAPS] --

vim.g.mapleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>")

vim.keymap.set("n", "+", "<C-a>", { silent = true, desc = "Increment number" })
vim.keymap.set("n", "-", "<C-x>", { silent = true, desc = "Decrement number" })

vim.keymap.set("n", "]b", ":bnext<CR>", { silent = true, desc = "Goto next [b]uffer" })
vim.keymap.set("n", "[b", ":bprevious<CR>", { silent = true, desc = "Goto previous [b]uffer" })

vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { silent = true, desc = "Goto next [d]iagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { silent = true, desc = "Goto previous [d]iagnostic" })

-- https://vim.fandom.com/wiki/Moving_lines_up_or_down
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

vim.keymap.set("v", "R", '"_dP', { silent = true, desc = "[R]eplace selection without overwriting buffer" })

-- [PLUGINS] --

-- install plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- UI --
    { "catppuccin/nvim",               name = "catppuccin", priority = 1000 },
    { "f-person/auto-dark-mode.nvim" },
    { "lewis6991/gitsigns.nvim" },
    -- EDITOR --
    { "echasnovski/mini.comment",      version = "*" },
    { "echasnovski/mini.completion",   version = "*" },
    { "echasnovski/mini.pairs",        version = "*" },
    { "kylechui/nvim-surround",        version = "*",       event = "VeryLazy" },
    -- TMUX --
    { "christoomey/vim-tmux-navigator" },
    -- FZF --
    { "ibhagwan/fzf-lua" },
    -- LSP --
    { "neovim/nvim-lspconfig" },
    { "kosayoda/nvim-lightbulb" },
})

-- [PLUGINS.UI] --
require("catppuccin").setup({ background = { light = "latte", dark = "frappe" } })
require("auto-dark-mode").setup({ update_interval = 1000 })
require("gitsigns").setup({})

vim.cmd.colorscheme("catppuccin")

-- [PLUGINS.EDITOR] --
require("mini.comment").setup({})
require("mini.completion").setup({})
require("mini.pairs").setup({
    mappings = {
        ["("] = { neigh_pattern = "[^\\][^%w]" },
        ["["] = { neigh_pattern = "[^\\][^%w]" },
        ["{"] = { neigh_pattern = "[^\\][^%w]" },
        ['"'] = { neigh_pattern = "[^%w\\][^%w]" },
        ["'"] = { neigh_pattern = "[^%w\\][^%w]" },
        ["`"] = { neigh_pattern = "[^%w\\][^%w]" },
    },
})
require("nvim-surround").setup({})

-- [PLUGINS.TMUX] --
vim.keymap.set({ "n", "v" }, "<S-Left>", ":TmuxNavigateLeft<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<S-Down>", ":TmuxNavigateDown<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<S-Up>", ":TmuxNavigateUp<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<S-Right>", ":TmuxNavigateRight<CR>", { silent = true })

-- [PLUGINS.FZF] --
require("fzf-lua").setup({})
vim.keymap.set("n", "<Leader><Leader>", ":FzfLua<CR>", { silent = true })
vim.keymap.set("n", "gf", ":FzfLua files<CR>", { silent = true, desc = "[G]oto [f]ile" })
vim.keymap.set("n", "gb", ":FzfLua buffers<CR>", { silent = true, desc = "[G]oto [b]uffer" })
vim.keymap.set("n", "<Leader>g", ":FzfLua live_grep<CR>", { silent = true, desc = "[G]rep project" })
vim.keymap.set("n", "<Leader>d", ":FzfLua diagnostics_document<CR>", { silent = true, desc = "Show [d]iagnostics" })
vim.keymap.set("n", "<Leader>'", ":FzfLua marks<CR>", { silent = true, desc = "Show marks" })
vim.keymap.set("n", '<Leader>"', ":FzfLua registers<CR>", { silent = true, desc = "Show registers" })
vim.keymap.set("n", "<Leader>:", ":FzfLua command_history<CR>", { silent = true, desc = "Show command history" })
vim.keymap.set("n", "<Leader>h", ":FzfLua help_tags<CR>", { silent = true, desc = "Show [h]elp tags" })

-- [PLUGINS.LSP] --
local on_attach = function(args)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, silent = true, desc = "[G]oto [d]efinition" })
    vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, { buffer = args.buf, silent = true, desc = "[G]oto type [d]efinition" })
    vim.keymap.set("n", "gr", ":FzfLua lsp_references<CR>", { buffer = args.buf, silent = true, desc = "[G]oto [r]eference" })
    vim.keymap.set("n", "gi", ":FzfLua lsp_implementations<CR>", { buffer = args.buf, silent = true, desc = "[G]oto [i]mplementation" })
    vim.keymap.set("n", "gs", ":FzfLua lsp_document_symbols<CR>", { buffer = args.buf, silent = true, desc = "[G]oto [s]ymbol" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = args.buf, silent = true, desc = "Show help" })
    vim.keymap.set("n", "<Leader>k", vim.lsp.buf.signature_help, { buffer = args.buf, silent = true, desc = "Show signature help" })
    vim.keymap.set("n", "<Leader>r", vim.lsp.buf.rename, { buffer = args.buf, silent = true, desc = "[R]ename symbol" })
    vim.keymap.set("n", "<Leader>f", vim.lsp.buf.format, { buffer = args.buf, silent = true, desc = "[F]ormat buffer" })
    vim.keymap.set("n", "<Leader>a", ":FzfLua lsp_code_actions<CR>", { buffer = args.buf, silent = true, desc = "Code [a]ctions" })
end

vim.api.nvim_create_autocmd("LspAttach", { callback = on_attach })

require("nvim-lightbulb").setup({
    autocmd = { enabled = true },
})

require("lspconfig").gopls.setup({})
require("lspconfig").clangd.setup({})
require("lspconfig").pyright.setup({})
require("lspconfig").ruff_lsp.setup({})
require("lspconfig").lua_ls.setup({
    -- https://luals.github.io/wiki/settings
    settings = {
        Lua = {
            workspace = {
                library = { vim.env.VIMRUNTIME },
            },
        },
    },
})
