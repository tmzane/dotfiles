local function setup_ui_options()
    -- statuscolumn: use custom format
    vim.opt.relativenumber = true
    vim.opt.signcolumn = "yes"
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

    -- ask to save unsaved changes
    vim.opt.confirm = true

    -- configure autocompletion
    vim.opt.completeopt = "menuone,popup,noinsert,fuzzy"

    -- treat header files as C code
    vim.g.c_syntax_for_h = true
end

local function setup_keymaps()
    vim.g.mapleader = " "

    vim.keymap.set("n", "L", ":bnext<CR>", { silent = true, desc = "Goto next buffer" })
    vim.keymap.set("n", "H", ":bprevious<CR>", { silent = true, desc = "Goto previous buffer" })

    -- https://vim.fandom.com/wiki/Fix_indentation
    vim.keymap.set("n", "g=", "gg=G<C-o><C-o>", { silent = true, desc = "Fix indentation" })

    -- https://vim.fandom.com/wiki/Moving_lines_up_or_down
    vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
    vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })

    vim.keymap.set("n", "<Esc>", ":nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlights" })

    vim.keymap.set("n", "\\r", function()
        vim.opt.wrap = not vim.opt.wrap:get()
        if vim.opt.conceallevel:get() == 0 then
            vim.opt.conceallevel = 2
        else
            vim.opt.conceallevel = 0
        end
    end, { silent = true, desc = "Toggle [r]eader view" })

    vim.opt.listchars = "tab:> ,space:·"
    vim.keymap.set("n", "\\c", function()
        vim.opt.list = not vim.opt.list:get()
    end, { silent = true, desc = "Toggle invisible [c]haracters" })
end

local function setup_plugin_manager()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    require("lazy").setup({
        { "christoomey/vim-tmux-navigator" },
        { "echasnovski/mini.icons",          version = "*" },
        { "echasnovski/mini.pairs",          version = "*" },
        { "echasnovski/mini.surround",       version = "*" },
        { "ibhagwan/fzf-lua",                dependencies = { "echasnovski/mini.icons" } },
        { "lewis6991/gitsigns.nvim" },
        { "neovim/nvim-lspconfig" },
        { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

        -- TODO: these are small, implement manually and remove.
        { "echasnovski/mini.bufremove",      version = "*" },
        { "f-person/auto-dark-mode.nvim" },
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
            local gitsigns = require("gitsigns")
            gitsigns.change_base("HEAD~1") -- diff against previous commit by default
            vim.keymap.set("n", "]h", gitsigns.next_hunk, { silent = true, desc = "Goto next git [h]unk" })
            vim.keymap.set("n", "[h", gitsigns.prev_hunk, { silent = true, desc = "Goto previous git [h]unk" })
            vim.keymap.set("n", "gh", gitsigns.preview_hunk_inline, { silent = true, desc = "Preview [g]it [h]unk" })
        end,
    })
end

local function setup_mini_plugins()
    local bufremove = require("mini.bufremove")
    bufremove.setup({})
    vim.keymap.set("n", "<BS>", bufremove.delete, { silent = true, desc = "Delete current buffer" })

    require("mini.icons").setup({})
    require("mini.pairs").setup({})
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
    fzf.register_ui_select()

    vim.keymap.set("n", "<Leader>f", fzf.files, { silent = true, desc = "Search [f]iles" })
    vim.keymap.set("n", "<Leader>b", fzf.buffers, { silent = true, desc = "Search [b]uffers" })
    vim.keymap.set("n", "<Leader>q", fzf.quickfix, { silent = true, desc = "Search [q]uickfix list" })
    vim.keymap.set("n", "<Leader>g", fzf.git_status, { silent = true, desc = "Search [g]it status" })
    vim.keymap.set("n", "<Leader>d", fzf.diagnostics_document, { silent = true, desc = "Search [d]iagnostics" })
    vim.keymap.set("n", "<Leader>h", fzf.help_tags, { silent = true, desc = "Search [h]elp tags" })
    vim.keymap.set("n", "<Leader>/", fzf.live_grep, { silent = true, desc = "Search with grep" })
    vim.keymap.set("n", "<Leader><Leader>", fzf.resume, { silent = true, desc = "Resume last query" })
    vim.keymap.set("n", "z=", fzf.spell_suggest, { silent = true, desc = "Spell suggestions" })

    fzf.setup({
        keymap = {
            fzf = {
                ["ctrl-q"] = "select-all+accept", -- send all to quickfix list
            },
        },
        file_ignore_patterns = { "^%.git/" },
    })
end

local function on_lsp_attach(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- disable semantic highlights in favor of Treesitter
    client.server_capabilities.semanticTokensProvider = nil

    -- enable autocompletion
    if client.supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    -- format the current buffer on save
    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = args.buf,
            callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
            end,
        })
    end

    local map = function(mode, key, desc, func)
        vim.keymap.set(mode, key, func, { buffer = args.buf, silent = true, desc = desc })
    end

    local fzf = require("fzf-lua")
    map("n", "gd", "[G]oto [d]efinition", function() fzf.lsp_definitions({ jump_to_single_result = true }) end)
    map("n", "gD", "[G]oto [d]eclaration", function() fzf.lsp_declarations({ jump_to_single_result = true }) end)
    map("n", "gt", "[G]oto [t]ype definition", function() fzf.lsp_typedefs({ jump_to_single_result = true }) end)
    map("n", "grr", "[G]oto [r]eference", function() fzf.lsp_references({ includeDeclaration = false }) end)
    map("n", "gri", "[G]oto [i]mplementation", fzf.lsp_implementations)
    map("n", "<Leader>s", "Search document [s]ymbols", fzf.lsp_document_symbols)
    map("n", "<Leader>S", "Search workspace [s]ymbols", fzf.lsp_workspace_symbols)
    map("n", "\\h", "Toggle inlay [h]ints", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end)
end

local function setup_lsp()
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_lsp_attach,
    })

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

    require("lspconfig").clangd.setup({
        cmd = { "/opt/homebrew/opt/llvm/bin/clangd" },
    })

    require("lspconfig").zls.setup({})
    require("lspconfig").rust_analyzer.setup({})
    require("lspconfig").pyright.setup({})
    require("lspconfig").ruff.setup({})

    require("lspconfig").lua_ls.setup({
        -- https://luals.github.io/wiki/settings
        settings = {
            Lua = {
                workspace = { library = { vim.env.VIMRUNTIME } },
            },
        },
    })
end

local function setup_treesitter()
    require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = { enable = true },
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

    return string.format(" %s ", join_non_empty(parts, "  "))
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

            local icon = require("mini.icons").get("file", name)
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
