local function setup_ui_options()
    -- show the number column
    vim.opt.number = true
    vim.opt.relativenumber = true

    -- always show the sign column
    vim.opt.signcolumn = "yes"

    -- do not wrap long lines
    vim.opt.wrap = false

    -- keep the cursor centered vertically
    vim.opt.scrolloff = 999

    -- use global status line
    vim.opt.laststatus = 3

    -- use sane window splitting
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
end

local function setup_editor_options()
    -- expand tabs to 4 spaces
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4

    -- ignore case in search patterns
    vim.opt.ignorecase = true
    vim.opt.smartcase = true

    -- always use the system clipboard
    vim.opt.clipboard = "unnamedplus"

    -- enable spell checking
    vim.opt.spell = true

    -- enable autosave
    vim.opt.autowrite = true
    vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
        command = ":wall",
    })

    -- treat header files as C code
    vim.g.c_syntax_for_h = true

    -- use // comments in C files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c" },
        callback = function() vim.bo.commentstring = "// %s" end,
    })

    -- disable optional providers
    vim.g.loaded_python3_provider = 0
    vim.g.loaded_ruby_provider = 0
    vim.g.loaded_node_provider = 0
    vim.g.loaded_perl_provider = 0
end

local function setup_keymaps()
    vim.g.mapleader = " "
    vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>")

    vim.keymap.set("n", "L", ":bnext<CR>", { silent = true, desc = "Goto next buffer" })
    vim.keymap.set("n", "H", ":bprevious<CR>", { silent = true, desc = "Goto previous buffer" })

    vim.keymap.set("n", "]q", ":cnext<CR>", { silent = true, desc = "Goto next [q]uickfix list entry" })
    vim.keymap.set("n", "[q", ":cprev<CR>", { silent = true, desc = "Goto previous [q]uickfix list entry" })

    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { silent = true, desc = "Goto next [d]iagnostic" })
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { silent = true, desc = "Goto previous [d]iagnostic" })

    -- https://vim.fandom.com/wiki/Moving_lines_up_or_down
    vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
    vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

    vim.keymap.set("n", "<Esc>", ":nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlights" })

    vim.keymap.set("i", "<Tab>", function()
        if vim.fn.pumvisible() ~= 0 then return "<C-n>" end
        return "<Tab>"
    end, { expr = true, silent = true, desc = "Next completion list entry" })

    vim.keymap.set("i", "<S-Tab>", function()
        if vim.fn.pumvisible() ~= 0 then return "<C-p>" end
        return "<S-Tab>"
    end, { expr = true, silent = true, desc = "Previous completion list entry" })
end

local function setup_plugin_manager()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    require("lazy").setup({
        { "catppuccin/nvim",                 name = "catppuccin",                             priority = 1000 },
        { "f-person/auto-dark-mode.nvim" },
        { "lewis6991/gitsigns.nvim" },
        { "nvim-lualine/lualine.nvim",       dependencies = { "nvim-tree/nvim-web-devicons" } },
        { "echasnovski/mini.bufremove",      version = "*" },
        { "echasnovski/mini.comment",        version = "*" },
        { "echasnovski/mini.completion",     version = "*" },
        { "echasnovski/mini.pairs",          version = "*" },
        { "echasnovski/mini.surround",       version = "*" },
        { "ibhagwan/fzf-lua",                dependencies = { "nvim-tree/nvim-web-devicons" } },
        { "neovim/nvim-lspconfig" },
        { "kosayoda/nvim-lightbulb" },
        { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
        { "christoomey/vim-tmux-navigator" },
    })
end

local function setup_colorscheme()
    local custom_highlights = function(colors)
        return {
            -- all
            ["@operator"] = { link = "@text" },
            ["@property"] = { link = "@variable" },
            ["@variable.member"] = { link = "@variable" },
            ["@variable.parameter"] = { link = "@variable" },
            ["@variable.builtin"] = { link = "@variable" },
            ["@constructor"] = { link = "@function" },
            ["@function.builtin"] = { link = "@function" },
            ["@attribute"] = { link = "@keyword" },
            ["@punctuation.bracket"] = { link = "@text" },
            ["@punctuation.delimiter"] = { link = "@text" },
            ["MatchParen"] = { fg = colors.Peach, bg = "" },
            -- C
            ["@keyword.directive.c"] = { link = "@keyword" },
            ["@keyword.directive.define.c"] = { link = "@keyword" },
            ["@keyword.conditional.ternary.c"] = { link = "@text" },
            -- Go
            ["@module.go"] = { link = "@text" },
            -- Zig
            ["@punctuation.special.zig"] = { link = "@text" },
            -- Lua
            ["@constructor.lua"] = { link = "@text" },
        }
    end

    require("catppuccin").setup({
        no_italic = true,
        background = { light = "latte", dark = "frappe" },
        custom_highlights = custom_highlights,
    })

    require("auto-dark-mode").setup({
        update_interval = 1000,
    })

    vim.cmd.colorscheme("catppuccin")
end

local function setup_gitsigns()
    require("gitsigns").setup({
        signs = {
            add          = { text = "+" },
            change       = { text = "~" },
            delete       = { text = "-" },
            topdelete    = { text = "-" },
            changedelete = { text = "~" },
            untracked    = { text = "+" },
        },
        on_attach = function()
            require("gitsigns").change_base("HEAD~1") -- diff against previous commit by default
            vim.keymap.set("n", "]h", ":Gitsigns next_hunk<CR><CR>", { silent = true, desc = "Goto next git [h]unk" })
            vim.keymap.set("n", "[h", ":Gitsigns prev_hunk<CR><CR>", { silent = true, desc = "Goto previous git [h]unk" })
            vim.keymap.set("n", "gh", ":Gitsigns preview_hunk_inline<CR>", { silent = true, desc = "Preview [g]it [h]unk" })
        end,
    })
end

local function setup_lualine()
    local lualine = require("lualine")

    vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = function() lualine.refresh() end,
    })
    vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = function() vim.defer_fn(lualine.refresh, 50) end,
    })

    local function macro_recording()
        local reg = vim.fn.reg_recording()
        if reg == "" then
            return ""
        end
        return "recording @" .. reg
    end

    lualine.setup({
        options = {
            section_separators = "",
            component_separators = "",
            globalstatus = true,
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = {},
            lualine_c = { { "buffers", symbols = { modified = "*", alternate_file = "" } } },
            lualine_x = { "diagnostics", "searchcount", "selectioncount", macro_recording },
            lualine_y = { "branch" },
            lualine_z = {},
        },
    })
end

local function setup_mini_plugins()
    local bufremove = require("mini.bufremove")
    bufremove.setup({})
    vim.keymap.set("n", "<BS>", bufremove.delete, { silent = true, desc = "Delete current buffer" })

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

    require("mini.surround").setup({
        mappings = {
            add = "gs",
            delete = "ds",
            replace = "cs",
            find = "",
            find_left = "",
            highlight = "",
            update_n_lines = "",
        },
    })
end

local function setup_fzf()
    require("fzf-lua").setup({})

    vim.keymap.set("n", "<Leader><Leader>", ":FzfLua buffers<CR>", { silent = true, desc = "[L]ist buffers" })
    vim.keymap.set("n", "<Leader>e", ":FzfLua files<CR>", { silent = true, desc = "[E]dit file" })
    vim.keymap.set("n", "<Leader>d", ":FzfLua diagnostics_document<CR>", { silent = true, desc = "[L]ist [d]iagnostics" })
    vim.keymap.set("n", "<Leader>h", ":FzfLua help_tags<CR>", { silent = true, desc = "Search [h]elp" })
    vim.keymap.set("n", "<Leader>/", ":FzfLua live_grep<CR>", { silent = true, desc = "Search in project" })
    vim.keymap.set("n", "<Leader>'", ":FzfLua marks<CR>", { silent = true, desc = "[L]ist marks" })
    vim.keymap.set("n", '<Leader>"', ":FzfLua registers<CR>", { silent = true, desc = "[L]ist registers" })
    vim.keymap.set("n", "<Leader>:", ":FzfLua command_history<CR>", { silent = true, desc = "[L]ist command history" })
end

local function setup_lsp()
    local on_attach = function(args)
        -- format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = args.buf,
            callback = function() vim.lsp.buf.format() end,
        })

        -- disable semantic highlights in favor of Treesitter
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        client.server_capabilities.semanticTokensProvider = nil

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, silent = true, desc = "[G]oto [d]efinition" })
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = args.buf, silent = true, desc = "[G]oto [d]eclaration" })
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = args.buf, silent = true, desc = "[G]oto [t]ype definition" })
        vim.keymap.set("n", "gr", ":FzfLua lsp_references<CR>", { buffer = args.buf, silent = true, desc = "[G]oto [r]eference" })
        vim.keymap.set("n", "gi", ":FzfLua lsp_implementations<CR>", { buffer = args.buf, silent = true, desc = "[G]oto [i]mplementation" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = args.buf, silent = true, desc = "Show help" })
        vim.keymap.set("n", "<Leader>r", vim.lsp.buf.rename, { buffer = args.buf, silent = true, desc = "[R]ename symbol" })
        vim.keymap.set("n", "<Leader>f", vim.lsp.buf.format, { buffer = args.buf, silent = true, desc = "[F]ormat buffer" })
        vim.keymap.set("n", "<Leader>s", ":FzfLua lsp_document_symbols<CR>", { buffer = args.buf, silent = true, desc = "[L]ist [s]ymbols" })
        vim.keymap.set("n", "<Leader>a", ":FzfLua lsp_code_actions<CR>", { buffer = args.buf, silent = true, desc = "[L]ist code [a]ctions" })
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_attach,
    })

    require("nvim-lightbulb").setup({
        autocmd = { enabled = true },
    })
end

local function setup_lsp_servers()
    -- C
    require("lspconfig").clangd.setup({
        cmd = { "/opt/homebrew/opt/llvm/bin/clangd" },
    })

    -- Go
    require("lspconfig").gopls.setup({
        settings = {
            gopls = {
                gofumpt = true,
            },
        },
    })

    -- Zig
    require("lspconfig").zls.setup({})

    -- Python
    require("lspconfig").pyright.setup({})
    require("lspconfig").ruff_lsp.setup({})

    -- Lua
    require("lspconfig").lua_ls.setup({
        -- https://luals.github.io/wiki/settings
        settings = {
            Lua = {
                workspace = { library = { vim.env.VIMRUNTIME } },
            },
        },
    })

    -- HTML
    require("lspconfig").html.setup({
        settings = {
            html = {
                format = { wrapLineLength = 999 },
            },
        },
    })

    -- CSS
    require("lspconfig").cssls.setup({})

    -- JSON
    require("lspconfig").jsonls.setup({})
end

local function setup_treesitter()
    require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = {
            enable = true,
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<CR>",
                node_incremental = "<CR>",
                node_decremental = "<BS>",
            },
        },
    })
end

local function setup_tmux_navigation()
    vim.keymap.set({ "n", "v" }, "<S-Left>", ":TmuxNavigateLeft<CR>", { silent = true })
    vim.keymap.set({ "n", "v" }, "<S-Down>", ":TmuxNavigateDown<CR>", { silent = true })
    vim.keymap.set({ "n", "v" }, "<S-Up>", ":TmuxNavigateUp<CR>", { silent = true })
    vim.keymap.set({ "n", "v" }, "<S-Right>", ":TmuxNavigateRight<CR>", { silent = true })
end

setup_ui_options()
setup_editor_options()
setup_keymaps()
setup_plugin_manager()
setup_colorscheme()
setup_gitsigns()
setup_lualine()
setup_mini_plugins()
setup_fzf()
setup_lsp()
setup_lsp_servers()
setup_treesitter()
setup_tmux_navigation()
