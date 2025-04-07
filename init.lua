local function setup_ui_options()
    -- statuscolumn: use custom format
    vim.o.relativenumber = true
    vim.o.signcolumn = "yes"
    vim.o.statuscolumn = "%=%{v:relnum?v:relnum:v:lnum} %s"

    -- statusline: make global, merge with cmdline, use custom format
    vim.o.laststatus = 3
    vim.o.cmdheight = 0
    vim.o.showcmdloc = "statusline"
    vim.o.statusline = "%!v:lua.StatusLine()"

    -- tabline: show if argc > 0, use custom format
    vim.o.showtabline = vim.fn.argc() == 0 and 0 or 2
    vim.o.tabline = "%!v:lua.TabLine()"

    -- cursorline: highlight, keep centered, make cursor blink
    vim.o.cursorline = true
    vim.o.scrolloff = 999
    vim.o.guicursor = vim.o.guicursor .. ",a:blinkon500-blinkoff500"

    -- do not wrap long lines
    vim.o.wrap = false

    -- use sane window splitting
    vim.o.splitbelow = true
    vim.o.splitright = true

    -- use rounded borders for floating windows
    vim.o.winborder = "rounded"

    -- show diagnostics on virtual lines
    vim.diagnostic.config({ virtual_lines = { current_line = true } })

    -- highlight yanked text
    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function() vim.hl.on_yank() end,
    })

    -- set vim.b.git_branch to use it in the statusline
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            vim.b.git_branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
        end,
    })
end

local function setup_editor_options()
    -- expand tabs to 4 spaces
    vim.o.expandtab = true
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4

    -- ignore case in search patterns
    vim.o.ignorecase = true
    vim.o.smartcase = true

    -- always use the system clipboard
    vim.o.clipboard = "unnamedplus"

    -- enable spell checking
    vim.o.spell = true
    vim.o.spelllang = "en_us,ru_ru"

    -- enable Russian keymaps in Normal mode
    vim.o.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"

    -- treat header files as C code
    vim.g.c_syntax_for_h = true

    -- enable autosave
    vim.o.autowriteall = true
    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        callback = function()
            if vim.bo.buftype == "" and not vim.bo.readonly then
                vim.cmd("silent write")
            end
        end,
    })
end

local function setup_keymaps()
    vim.g.mapleader = " "

    vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")

    -- toggle [r]eader view
    vim.keymap.set("n", "\\r", function()
        vim.o.wrap = not vim.o.wrap
        if vim.o.conceallevel == 0 then
            vim.o.conceallevel = 2
        else
            vim.o.conceallevel = 0
        end
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end)

    -- toggle hidden [c]haracters
    vim.o.listchars = "tab:> ,space:·"
    vim.keymap.set("n", "\\c", function() vim.o.list = not vim.o.list end)
end

local function setup_arglist()
    --- Returns the buffer's position in the argument list, or -1 if not found.
    ---
    --- @param buf integer Buffer id, or 0 for the current buffer
    --- @return integer
    local get_buf_pos_in_arglist = function(buf)
        local args = vim.fn.argv()
        assert(type(args) == "table")
        for i, arg in ipairs(args) do
            if vim.fn.fnamemodify(arg, ":p") == vim.api.nvim_buf_get_name(buf) then
                return i
            end
        end
        return -1
    end

    -- automatically set argidx to the current buffer if it exists in the argument list.
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
            local pos = get_buf_pos_in_arglist(args.buf)
            if pos ~= -1 then
                vim.cmd("argument" .. tostring(pos))
            end
        end,
    })

    -- add/delete the current buffer to/from the argument list.
    vim.keymap.set("n", "m", function()
        if get_buf_pos_in_arglist(0) == -1 then
            vim.cmd("$argedit %")
        else
            vim.cmd("argdelete %")
            if vim.fn.argidx() > 0 then
                vim.cmd("prev | edit #") -- set argidx to the previous file keeping the current buffer open.
            end
        end

        vim.o.showtabline = vim.fn.argc() == 0 and 0 or 2
        vim.api.nvim__redraw({ tabline = true })
    end)

    -- edit the previous file in the argument list.
    vim.keymap.set("n", "H", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 then
            vim.cmd("first")
        elseif vim.fn.argidx() == 0 then
            vim.cmd("last")
        else
            vim.cmd("prev")
        end
    end)

    -- edit the next file in the argument list.
    vim.keymap.set("n", "L", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 then
            vim.cmd("last")
        elseif vim.fn.argidx() == vim.fn.argc() - 1 then
            vim.cmd("first")
        else
            vim.cmd("next")
        end
    end)

    -- edit the nth file in the argument list.
    for i = 1, 9 do
        vim.keymap.set("n", "g" .. tostring(i), function()
            vim.cmd("argument" .. tostring(i))
        end)
    end
end

local function setup_plugin_manager()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.uv.fs_stat(lazypath) then
        vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
    end
    vim.o.rtp = lazypath .. "," .. vim.o.rtp

    require("lazy").setup({
        { "christoomey/vim-tmux-navigator" },
        { "echasnovski/mini.icons",          version = "*" },
        { "echasnovski/mini.surround",       version = "*" },
        { "f-person/auto-dark-mode.nvim" },
        { "ibhagwan/fzf-lua",                dependencies = { "echasnovski/mini.icons" } },
        { "lewis6991/gitsigns.nvim" },
        { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    })
end

local function setup_colorscheme()
    require("auto-dark-mode").setup({ update_interval = 1000 })
end

local function setup_gitsigns()
    require("gitsigns").setup({
        on_attach = function()
            local gitsigns = require("gitsigns")
            gitsigns.change_base("HEAD~1") -- diff against previous commit by default

            vim.keymap.set("n", "]h", gitsigns.next_hunk)
            vim.keymap.set("n", "[h", gitsigns.prev_hunk)
            vim.keymap.set("n", "gh", gitsigns.preview_hunk_inline)
            vim.keymap.set("n", "gH", gitsigns.reset_hunk)
        end,
    })
end

local function setup_mini()
    require("mini.icons").setup({})
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

-- https://github.com/ibhagwan/fzf-lua/wiki
local function setup_fzf()
    local fzf = require("fzf-lua")

    fzf.setup({
        "hide",
        keymap = {
            fzf = {
                ["ctrl-q"] = "select-all+accept", -- send all to quickfix list
            },
        },
    })

    fzf.register_ui_select()

    vim.keymap.set("n", "<Leader>a", fzf.args)
    vim.keymap.set("n", "<Leader>b", fzf.buffers)
    vim.keymap.set("n", "<Leader>d", fzf.diagnostics_document)
    vim.keymap.set("n", "<Leader>f", fzf.files)
    vim.keymap.set("n", "<Leader>g", fzf.git_status)
    vim.keymap.set("n", "<Leader>h", fzf.help_tags)
    vim.keymap.set("n", "<Leader>q", fzf.quickfix)
    vim.keymap.set("n", "<Leader>r", fzf.resume)
    vim.keymap.set("n", "<Leader>/", fzf.live_grep)
    vim.keymap.set("n", "<Leader><Leader>", fzf.builtin)
    vim.keymap.set("n", "z=", fzf.spell_suggest)
end

local function on_lsp_attach(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- disable semantic highlights in favor of Treesitter
    client.server_capabilities.semanticTokensProvider = nil

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
        vim.o.completeopt = "menuone,popup,noinsert,fuzzy"
        vim.lsp.completion.enable(true, client.id, args.buf)
        vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get)
        vim.keymap.set("i", "<CR>", function()
            return vim.fn.pumvisible() ~= 0 and "<C-y>" or "<CR>"
        end, { expr = true })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_formatting) then
        vim.keymap.set("n", "<CR>", function()
            vim.lsp.buf.format()
            -- TODO: make sync and silent
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
        end)
    end

    local fzf = require("fzf-lua")
    vim.keymap.set("n", "gd", fzf.lsp_definitions)
    vim.keymap.set("n", "gD", fzf.lsp_declarations)
    vim.keymap.set("n", "gt", fzf.lsp_typedefs)
    vim.keymap.set("n", "grr", function() fzf.lsp_references({ jump1 = false, includeDeclaration = false }) end)
    vim.keymap.set("n", "gri", function() fzf.lsp_implementations({ jump1 = false }) end)
    vim.keymap.set("n", "gO", fzf.lsp_document_symbols)
    vim.keymap.set("n", "<Leader>s", fzf.lsp_live_workspace_symbols)
end

-- https://neovim.io/doc/user/lsp.html
local function setup_lsp()
    vim.lsp.config["gopls"] = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.mod", "go.work", ".git" },
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
    }

    vim.lsp.config["clangd"] = {
        cmd = { "/opt/homebrew/opt/llvm/bin/clangd", "--background-index" },
        filetypes = { "c" },
        root_markers = { ".clangd", "compile_commands.json", ".git" },
    }

    vim.lsp.config["zls"] = {
        cmd = { "zls" },
        filetypes = { "zig" },
        root_markers = { "build.zig", ".git" },
    }

    vim.lsp.config["pyright"] = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "requirements.txt", ".git" },
        settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    diagnosticMode = "openFilesOnly",
                    useLibraryCodeForTypes = true,
                },
            },
        },
    }

    vim.lsp.config["ruff"] = {
        cmd = { "ruff", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", ".git" },
    }

    vim.lsp.config["luals"] = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".git" },
        settings = {
            Lua = {
                -- https://luals.github.io/wiki/settings
                runtime = { version = "LuaJIT" },
                workspace = { library = { vim.env.VIMRUNTIME } },
            },
        },
    }

    vim.lsp.enable({ "gopls", "clangd", "zls", "ruff", "pyright", "luals" })
    vim.api.nvim_create_autocmd("LspAttach", { callback = on_lsp_attach })
end

local function setup_treesitter()
    require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
    })
end

local function setup_tmux_navigation()
    vim.keymap.set({ "n", "v" }, "<S-Left>", "<Cmd>TmuxNavigateLeft<CR>")
    vim.keymap.set({ "n", "v" }, "<S-Down>", "<Cmd>TmuxNavigateDown<CR>")
    vim.keymap.set({ "n", "v" }, "<S-Up>", "<Cmd>TmuxNavigateUp<CR>")
    vim.keymap.set({ "n", "v" }, "<S-Right>", "<Cmd>TmuxNavigateRight<CR>")
end

setup_ui_options()
setup_editor_options()
setup_keymaps()
setup_arglist()
setup_plugin_manager()
setup_colorscheme()
setup_gitsigns()
setup_mini()
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

    local attached_lsp = function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local names = vim.tbl_map(function(c) return c.name end, clients)
        return table.concat(names, "+")
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
        attached_lsp(),
        "%l/%L (%p%%)", -- line number / total lines (file progress in %)
        vim.b.git_branch,
    }

    return string.format(" %s ", join_non_empty(parts, "  "))
end

function TabLine()
    local tabs = {}
    local args = vim.fn.argv()
    assert(type(args) == "table")

    for i, arg in ipairs(args) do
        local tab = string.format(" %d %s ", i, vim.fn.fnamemodify(arg, ":t"))
        if vim.fn.fnamemodify(arg, ":p") == vim.api.nvim_buf_get_name(0) then
            table.insert(tabs, "%#Normal#" .. tab .. "%#TabLine#")
        else
            table.insert(tabs, tab)
        end
    end

    return table.concat(tabs, "")
end
