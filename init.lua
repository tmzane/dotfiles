local function setup_ui_options()
    -- statuscolumn: use custom format
    vim.opt.relativenumber = true
    vim.opt.statuscolumn = "%=%{v:relnum?v:relnum:v:lnum} %s"

    -- statusline: make global, merge with cmdline, use custom format
    vim.opt.laststatus = 3
    vim.opt.cmdheight = 0
    vim.opt.showcmdloc = "statusline"
    vim.opt.statusline = "%!v:lua.StatusLine()"

    -- tabline: always show, use custom format
    vim.opt.showtabline = 2
    vim.opt.tabline = "%!v:lua.TabLine()"

    -- cursorline: highlight, keep centered, make cursor blink
    vim.opt.cursorline = true
    vim.opt.scrolloff = 999
    vim.opt.guicursor:append("a:blinkon500")

    -- do not wrap long lines
    vim.opt.wrap = false

    -- use sane window splitting
    vim.opt.splitbelow = true
    vim.opt.splitright = true

    -- highlight yanked text
    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function() vim.highlight.on_yank() end,
    })
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

    -- https://vim.fandom.com/wiki/Fix_indentation
    vim.keymap.set("n", "g=", "gg=G<C-o><C-o>", { silent = true, desc = "Fix indentation" })

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

    vim.opt.listchars = "tab:> ,space:·" -- TODO: always show extends:…,precedes:…
    vim.keymap.set("n", "\\c", function()
        vim.opt.list = not vim.opt.list:get()
    end, { silent = true, desc = "Toggle invisible [c]haracters" })

    vim.keymap.set("n", "\\r", function()
        if vim.opt.conceallevel:get() == 0 then
            vim.opt.conceallevel = 2
        else
            vim.opt.conceallevel = 0
        end
    end, { silent = true, desc = "Toggle markdown [r]endering" })
end

local function setup_plugin_manager()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    require("lazy").setup({
        { "christoomey/vim-tmux-navigator" },
        { "echasnovski/mini.bufremove",      version = false },
        { "echasnovski/mini.completion",     version = false },
        { "echasnovski/mini.pairs",          version = false },
        { "echasnovski/mini.surround",       version = false },
        { "f-person/auto-dark-mode.nvim" },
        { "ibhagwan/fzf-lua",                dependencies = { "nvim-tree/nvim-web-devicons" } },
        { "kosayoda/nvim-lightbulb" },
        { "lewis6991/gitsigns.nvim" },
        { "neovim/nvim-lspconfig" },
        { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    })
end

local function setup_colorscheme()
    require("auto-dark-mode").setup({
        update_interval = 1000,
    })
end

local function setup_gitsigns()
    require("gitsigns").setup({
        on_attach = function()
            require("gitsigns").change_base("HEAD~1") -- diff against previous commit by default
            vim.keymap.set("n", "]h", ":Gitsigns next_hunk<CR><CR>", { silent = true, desc = "Goto next git [h]unk" })
            vim.keymap.set("n", "[h", ":Gitsigns prev_hunk<CR><CR>", { silent = true, desc = "Goto previous git [h]unk" })
            vim.keymap.set("n", "gh", ":Gitsigns preview_hunk_inline<CR>", { silent = true, desc = "Preview [g]it [h]unk" })
        end,
    })
end

local function setup_mini_plugins()
    local bufremove = require("mini.bufremove")
    bufremove.setup({})
    vim.keymap.set("n", "<BS>", bufremove.delete, { silent = true, desc = "Delete current buffer" })

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
    local fzf = require("fzf-lua")

    fzf.setup({
        "fzf-tmux",
        keymap = {
            fzf = {
                ["ctrl-q"] = "select-all+accept", -- send all to quickfix list
            },
        },
        file_ignore_patterns = { "^%.git/" },
    })

    vim.keymap.set("n", "<Leader>f", fzf.files, { silent = true, desc = "Search [f]iles" })
    vim.keymap.set("n", "<Leader>b", fzf.buffers, { silent = true, desc = "Search [b]uffers" })
    vim.keymap.set("n", "<Leader>d", fzf.diagnostics_document, { silent = true, desc = "Search [d]iagnostics" })
    vim.keymap.set("n", "<Leader>c", fzf.commands, { silent = true, desc = "Search [c]ommands" })
    vim.keymap.set("n", "<Leader>q", fzf.quickfix, { silent = true, desc = "Search [q]uickfix list" })
    vim.keymap.set("n", "<Leader>g", fzf.git_status, { silent = true, desc = "Search [g]it status" })
    vim.keymap.set("n", "<Leader>h", fzf.help_tags, { silent = true, desc = "Search [h]elp tags" })
    vim.keymap.set("n", "<Leader>/", fzf.live_grep, { silent = true, desc = "Search with grep" })
    vim.keymap.set("n", '<Leader>"', fzf.registers, { silent = true, desc = "Search registers" })
    vim.keymap.set("n", "<Leader>:", fzf.command_history, { silent = true, desc = "Search command history" })
    vim.keymap.set("n", "<Leader><Leader>", fzf.resume, { silent = true, desc = "Resume last query" })
end

local function on_lsp_attach(args)
    -- format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        callback = function() vim.lsp.buf.format() end,
    })

    -- disable semantic highlights in favor of Treesitter
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    client.server_capabilities.semanticTokensProvider = nil

    local map = function(mode, key, desc, func)
        vim.keymap.set(mode, key, func, { buffer = args.buf, silent = true, desc = desc })
    end

    local fzf = require("fzf-lua")
    map("n", "gd", "[G]oto [d]efinition", function() fzf.lsp_definitions({ jump_to_single_result = true }) end)
    map("n", "gD", "[G]oto [d]eclaration", function() fzf.lsp_declarations({ jump_to_single_result = true }) end)
    map("n", "gt", "[G]oto [t]ype definition", function() fzf.lsp_typedefs({ jump_to_single_result = true }) end)
    map("n", "gr", "[G]oto [r]eference", function() fzf.lsp_references({ jump_to_single_result = true, ignore_current_line = true, includeDeclaration = false }) end)
    map("n", "gi", "[G]oto [i]mplementation", function() fzf.lsp_implementations({ jump_to_single_result = true }) end)
    map("n", "g=", "Format buffer", vim.lsp.buf.format)
    map("i", "<C-s>", "Show signature help", vim.lsp.buf.signature_help)

    map("n", "glr", "[L]SP: [R]ename symbol", vim.lsp.buf.rename)
    map("n", "gla", "[L]SP: [C]ode actions", fzf.lsp_code_actions)

    map("n", "<Leader>s", "Search document [s]ymbols", fzf.lsp_document_symbols)
    map("n", "<Leader>S", "Search workspace [s]ymbols", fzf.lsp_workspace_symbols)

    map("n", "\\h", "Toggle inlay [h]ints", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end)
end

local function setup_lsp()
    vim.api.nvim_create_autocmd("LspAttach", { callback = on_lsp_attach })
    require("nvim-lightbulb").setup({ autocmd = { enabled = true } })

    -- C
    require("lspconfig").clangd.setup({
        cmd = { "/opt/homebrew/opt/llvm/bin/clangd" },
    })

    -- Go
    require("lspconfig").gopls.setup({
        settings = {
            gopls = {
                gofumpt = true,
                staticcheck = true,
                hints = {
                    -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    })

    -- Zig
    require("lspconfig").zls.setup({})

    -- Python
    require("lspconfig").pyright.setup({})
    require("lspconfig").ruff.setup({})

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
setup_mini_plugins()
setup_fzf()
setup_lsp()
setup_treesitter()
setup_tmux_navigation()

function StatusLine()
    local current_mode = function()
        local modes = {
            ["n"] = "NORMAL",
            ["v"] = "VISUAL",
            ["V"] = "V-LINE",
            [""] = "V-BLOCK",
            ["s"] = "SELECT",
            ["S"] = "S-LINE",
            [""] = "S-BLOCK",
            ["i"] = "INSERT",
            ["R"] = "REPLACE",
            ["c"] = "COMMAND",
            ["r"] = "PROMPT",
            ["!"] = "SHELL",
            ["t"] = "TERMINAL",
        }
        return modes[vim.fn.mode()]
    end

    local macro_recording = function()
        local reg = vim.fn.reg_recording()
        if reg == "" then
            return ""
        end
        return "recording @" .. reg
    end

    local search_count = function()
        local ok, count = pcall(vim.fn.searchcount)
        if not ok or vim.v.hlsearch == 0 then
            return ""
        end
        return " " .. count.current .. "/" .. count.total
    end

    local diagnostic_count = function(severity)
        local n = vim.diagnostic.count(0)[severity] or 0
        if n == 0 then
            return ""
        end
        return vim.diagnostic.severity[severity]:sub(1, 1) .. n
    end

    local with_hl = function(name, s)
        if s == "" then
            return ""
        end
        return "%#" .. name .. "#" .. s .. "%#StatusLine#"
    end

    local join_non_empty = function(list, sep)
        list = vim.tbl_filter(function(s) return s ~= "" end, list)
        return table.concat(list, sep)
    end

    vim.api.nvim_set_hl(0, "StatusLine", { link = "Normal" })

    local parts = {
        with_hl("Statement", current_mode()),
        "%F %m", -- filepath and modified flag
        "%=",    -- separation point
        "%S",    -- pending operator or number of selected characters
        macro_recording(),
        search_count(),
        join_non_empty({
            with_hl("DiagnosticSignError", diagnostic_count(vim.diagnostic.severity.ERROR)),
            with_hl("DiagnosticSignWarn", diagnostic_count(vim.diagnostic.severity.WARN)),
            with_hl("DiagnosticSignInfo", diagnostic_count(vim.diagnostic.severity.INFO)),
            with_hl("DiagnosticSignHint", diagnostic_count(vim.diagnostic.severity.HINT)),
        }, " "),
        "%l/%L (%p%%)", -- line number / total lines (file progress in %)
        vim.b.gitsigns_head,
    }

    return " " .. join_non_empty(parts, "  ") .. " "
end

function TabLine()
    local tabs = {}

    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buffer].buflisted then
            local name = vim.api.nvim_buf_get_name(buffer)

            if vim.bo[buffer].buftype == "quickfix" then
                name = "[Quickfix List]"
            end
            if name == "" then
                name = "[No Name]"
            end

            local devicons = require("nvim-web-devicons")
            local icon = devicons.get_icon(name, nil, { default = true })

            name = vim.fn.fnamemodify(name, ":~:.")
            name = string.format(" %s %s ", icon, name)

            if buffer == vim.api.nvim_get_current_buf() then
                table.insert(tabs, "%#TabLineSel#" .. name .. "%#TabLine#")
            else
                table.insert(tabs, name)
            end
        end
    end

    return table.concat(tabs, "")
end
