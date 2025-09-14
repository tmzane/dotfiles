local function setup_options()
    vim.o.autowriteall = true
    vim.o.clipboard = "unnamedplus"
    vim.o.cmdheight = 0
    vim.o.completeopt = "fuzzy,menuone,noinsert,popup"
    vim.o.confirm = true
    vim.o.cursorline = true
    vim.o.expandtab = true
    vim.o.guicursor = vim.o.guicursor .. ",a:blinkon500-blinkoff500"
    vim.o.ignorecase = true
    vim.o.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
    vim.o.laststatus = 3
    vim.o.list = true
    vim.o.listchars = "tab:  ,trail:·"
    vim.o.relativenumber = true
    vim.o.scrolloff = 999
    vim.o.shiftwidth = 4
    vim.o.showcmdloc = "statusline"
    vim.o.showtabline = vim.fn.argc() == 0 and 0 or 2
    vim.o.signcolumn = "yes"
    vim.o.smartcase = true
    vim.o.spell = true
    vim.o.spelllang = "en_us,ru_ru"
    vim.o.splitbelow = true
    vim.o.splitright = true
    vim.o.statuscolumn = "%=%{v:relnum?v:relnum:v:lnum} %s"
    vim.o.statusline = "%!v:lua.StatusLine()"
    vim.o.swapfile = false
    vim.o.tabline = "%!v:lua.TabLine()"
    vim.o.tabstop = 4
    vim.o.undofile = true
    vim.o.winborder = "single"
    vim.o.wrap = false

    vim.g.c_syntax_for_h = true
    vim.g.mapleader = " "

    vim.diagnostic.config({ virtual_lines = { current_line = true } })
end

local function setup_keymaps()
    vim.keymap.set("n", "gd", "<C-]>")
    vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>")
    vim.keymap.set("n", "<S-Up>", "<Cmd>wincmd k<CR>")
    vim.keymap.set("n", "<S-Down>", "<Cmd>wincmd j<CR>")
    vim.keymap.set("n", "<S-Left>", "<Cmd>wincmd h<CR>")
    vim.keymap.set("n", "<S-Right>", "<Cmd>wincmd l<CR>")

    vim.keymap.set("i", "<CR>", function()
        return vim.fn.pumvisible() ~= 0 and "<C-y>" or "<CR>"
    end, { expr = true })
end

local function setup_autocmds()
    vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "highlight text on yank",
        callback = function()
            vim.hl.on_yank()
        end,
    })

    vim.api.nvim_create_autocmd("BufRead", {
        desc = "set current git branch",
        callback = function()
            vim.b.git_branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        desc = "use *_test.go files as alternate files",
        pattern = "go",
        callback = function(args)
            vim.keymap.set("n", "<C-6>", function()
                local altfile = ""
                local start = args.file:find("_test.go$")
                if start then
                    altfile = args.file:sub(1, start - 1) .. ".go"
                else
                    altfile = args.file:sub(1, - #".go" - 1) .. "_test.go"
                end
                if vim.uv.fs_stat(altfile) then
                    vim.cmd("edit " .. altfile)
                end
            end, { buffer = args.buf })
        end,
    })

    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        desc = "autowrite files on change",
        nested = true,
        callback = function(args)
            if args.file == "" or -- [No Name]
                vim.bo[args.buf].buftype ~= "" or
                vim.bo[args.buf].readonly
            then
                return
            end
            -- keep trailing whitespace on the current line.
            local ws = vim.api.nvim_get_current_line():match("%s+$")
            vim.cmd("silent write")
            if ws then
                vim.api.nvim_put({ ws }, "c", true, true)
                vim.cmd("noautocmd silent write")
            end
        end,
    })
end

local function setup_user_commands() end

local function setup_arglist()
    --- Returns the buffer's position in the argument list, or -1 if not found.
    ---
    --- @param buf integer Buffer id, or 0 for the current buffer.
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
                -- this command does :edit %, which unloads the current buffer,
                -- rereads it, and triggers BufUnload -> BufRead -> BufEnter.
                -- however, because this happens in an autocommand, no events will be triggered.
                -- this can break plugins that rely on these events,
                -- e.g. Gitsigns reattaches on BufRead after the buffer is reloaded.
                -- we can't use nested=true because BufEnter will cause recursion, so instead we fire BufRead manually.
                vim.cmd("keepjumps argument" .. tostring(pos))
                vim.cmd("doautocmd BufRead")
            end
        end,
    })

    -- add/delete the current buffer to/from the argument list.
    vim.keymap.set("n", "ga", function()
        if get_buf_pos_in_arglist(0) == -1 then
            vim.cmd("$argedit %")
        else
            vim.cmd("argdelete")
            if vim.fn.argc() > 0 then
                vim.cmd("argument")
            end
        end

        vim.o.showtabline = vim.fn.argc() == 0 and 0 or 2
        vim.api.nvim__redraw({ tabline = true })
    end)

    -- edit the previous file in the argument list.
    vim.keymap.set("n", "H", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 or vim.fn.argidx() == 0 then
            vim.cmd("last")
        else
            vim.cmd("prev")
        end
    end)

    -- edit the next file in the argument list.
    vim.keymap.set("n", "L", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 or vim.fn.argidx() == vim.fn.argc() - 1 then
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

local function setup_plugins()
    -- https://github.com/folke/lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.uv.fs_stat(lazypath) then
        vim.fn.system({ "git", "clone", "--branch=stable", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
    end
    vim.o.rtp = lazypath .. "," .. vim.o.rtp

    require("lazy").setup({
        { "echasnovski/mini.surround",                  version = "*" },
        { "ibhagwan/fzf-lua" },
        { "lewis6991/gitsigns.nvim" },
        { "nvim-treesitter/nvim-treesitter",            build = ":TSUpdate" },
        { "nvim-treesitter/nvim-treesitter-context" },
        { "nvim-treesitter/nvim-treesitter-textobjects" },
    })

    -- https://github.com/echasnovski/mini.surround
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

    -- https://github.com/lewis6991/gitsigns.nvim
    require("gitsigns").setup({
        on_attach = function(buf)
            local gitsigns = require("gitsigns")
            vim.keymap.set("n", "gh", gitsigns.preview_hunk_inline, { buffer = buf })
            vim.keymap.set("n", "gH", gitsigns.reset_hunk, { buffer = buf })

            local moves = require("nvim-treesitter.textobjects.repeatable_move")
            local next_hunk, prev_hunk = moves.make_repeatable_move_pair(gitsigns.next_hunk, gitsigns.prev_hunk)
            vim.keymap.set("n", "]c", next_hunk, { buffer = buf })
            vim.keymap.set("n", "[c", prev_hunk, { buffer = buf })
        end,
    })
    require("gitsigns").change_base("HEAD", true) -- show both staged and unstaged changes.
end

local function setup_fzf()
    -- https://github.com/ibhagwan/fzf-lua
    local fzf = require("fzf-lua")

    fzf.setup({
        "hide",
        winopts = {
            height  = 0.9,
            width   = 0.9,
            row     = 0.5,
            col     = 0.5,
            border  = "single",
            preview = {
                border = "single",
            },
        },
        keymap = {
            builtin = {
                true,
                ["<S-Up>"]   = "preview-up",
                ["<S-Down>"] = "preview-down",
            },
            fzf = {
                true,
                ["ctrl-q"] = "select-all+accept",
            },
        },
    })

    vim.keymap.set("n", "<Leader>a", fzf.args)
    vim.keymap.set("n", "<Leader>b", fzf.buffers)
    vim.keymap.set("n", "<Leader>d", fzf.diagnostics_document)
    vim.keymap.set("n", "<Leader>D", fzf.diagnostics_workspace)
    vim.keymap.set("n", "<Leader>f", fzf.files)
    vim.keymap.set("n", "<Leader>F", function() fzf.files({ cwd = "~" }) end)
    vim.keymap.set("n", "<Leader>g", fzf.git_diff)
    vim.keymap.set("n", "<Leader>h", fzf.help_tags)
    vim.keymap.set("n", "<Leader>l", fzf.loclist)
    vim.keymap.set("n", "<Leader>m", fzf.marks)
    vim.keymap.set("n", "<Leader>o", fzf.oldfiles)
    vim.keymap.set("n", "<Leader>q", fzf.quickfix)
    vim.keymap.set("n", "<Leader>/", fzf.grep_project)
    vim.keymap.set("n", "<Leader><Leader>", fzf.resume)
    vim.keymap.set("n", "z=", fzf.spell_suggest)
end

--- @param args vim.api.keyset.create_autocmd.callback_args
local function on_lsp_attach(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, { buffer = args.buf })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_formatting) then
        vim.keymap.set("n", "<CR>", function()
            vim.lsp.buf.format({ async = true })
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
        end, { buffer = args.buf })
    end

    local fzf = require("fzf-lua")
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = args.buf })
    vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = args.buf })
    vim.keymap.set("n", "<Leader>r", function() fzf.lsp_references({ jump1 = false, includeDeclaration = false }) end, { buffer = args.buf })
    vim.keymap.set("n", "<Leader>i", function() fzf.lsp_implementations({ jump1 = false }) end, { buffer = args.buf })
    vim.keymap.set("n", "<Leader>s", fzf.lsp_document_symbols, { buffer = args.buf })
    vim.keymap.set("n", "<Leader>S", fzf.lsp_live_workspace_symbols, { buffer = args.buf })
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
                workspace = {
                    library = {
                        vim.env.VIMRUNTIME,
                        vim.fn.stdpath("data") .. "/lazy",
                    },
                },
            },
        },
    }

    vim.lsp.enable({
        "gopls",
        "clangd",
        "zls",
        "ruff",
        "pyright",
        "luals",
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_lsp_attach,
    })
end

local function setup_treesitter()
    -- https://github.com/nvim-treesitter/nvim-treesitter
    -- https://github.com/nvim-treesitter/nvim-treesitter-context
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    require("nvim-treesitter.configs").setup({
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["if"] = "@function.inner",
                    ["af"] = "@function.outer",
                    ["ic"] = "@class.inner",
                    ["ac"] = "@class.outer",
                },
                include_surrounding_whitespace = true,
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]f"] = "@function.outer",
                    ["]c"] = "@class.outer",
                },
                goto_previous_start = {
                    ["[f"] = "@function.outer",
                    ["[c"] = "@class.outer",
                },
            },
        },
    })

    require("treesitter-context").setup({})

    local moves = require("nvim-treesitter.textobjects.repeatable_move")
    vim.keymap.set("n", ";", moves.repeat_last_move_next)
    vim.keymap.set("n", ",", moves.repeat_last_move_previous)
    vim.keymap.set("n", "f", moves.builtin_f_expr, { expr = true })
    vim.keymap.set("n", "F", moves.builtin_F_expr, { expr = true })
    vim.keymap.set("n", "t", moves.builtin_t_expr, { expr = true })
    vim.keymap.set("n", "T", moves.builtin_T_expr, { expr = true })

    local next_diagnostic, prev_diagnostic = moves.make_repeatable_move_pair(
        function() vim.diagnostic.jump({ count = 1 }) end,
        function() vim.diagnostic.jump({ count = -1 }) end
    )
    vim.keymap.set("n", "]d", next_diagnostic)
    vim.keymap.set("n", "[d", prev_diagnostic)
end

--- @type fun(): string
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

--- @type fun(): string
function TabLine()
    local tabs = {}
    local args = vim.fn.argv()
    assert(type(args) == "table")

    for i, arg in ipairs(args) do
        local tab = string.format(" %d:%s ", i, vim.fn.fnamemodify(arg, ":t"))
        if vim.fn.fnamemodify(arg, ":p") == vim.api.nvim_buf_get_name(0) then
            table.insert(tabs, "%#Normal#" .. tab .. "%#TabLine#")
        else
            table.insert(tabs, tab)
        end
    end

    return table.concat(tabs, "")
end

setup_options()
setup_keymaps()
setup_autocmds()
setup_user_commands()
setup_arglist()
setup_plugins()
setup_fzf()
setup_lsp()
setup_treesitter()
