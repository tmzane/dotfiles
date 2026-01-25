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

    require("vim._extui").enable({})
end

--- Creates mappings for the next and previous moves repeatable with the ; and , keys.
---
--- @class Move
--- @field key string
--- @field fn function
--- @param next Move
--- @param prev Move
--- @param opts? vim.keymap.set.Opts
local function map_repeatable_move(next, prev, opts)
    for _, move in ipairs({ next, prev }) do
        vim.keymap.set("n", move.key, function()
            vim.keymap.set("n", ";", function() vim.fn.feedkeys(next.key) end)
            vim.keymap.set("n", ",", function() vim.fn.feedkeys(prev.key) end)
            move.fn()
        end, opts)
    end
end

local function setup_keymaps()
    vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })
    vim.keymap.set("n", "gd", "<C-]>", { desc = "Goto definition" })
    vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

    vim.keymap.set("n", "<A-q>", function()
        for _, win in ipairs(vim.fn.getwininfo()) do
            if win.quickfix == 1 then
                vim.cmd.cclose()
                return
            end
        end
        vim.cmd.copen()
    end, { desc = "Toggle quickfix list" })

    for _, key in ipairs({ "f", "F", "t", "T" }) do
        vim.keymap.set("n", key, function()
            pcall(vim.keymap.del, "n", ";")
            pcall(vim.keymap.del, "n", ",")
            return key
        end, { expr = true })
    end

    map_repeatable_move(
        { key = "]q", fn = vim.cmd.cnext },
        { key = "[q", fn = vim.cmd.cprev }
    )
    map_repeatable_move(
        { key = "]d", fn = function() vim.diagnostic.jump({ count = 1 }) end },
        { key = "[d", fn = function() vim.diagnostic.jump({ count = -1 }) end }
    )
    map_repeatable_move(
        { key = "]w", fn = function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN }) end },
        { key = "[w", fn = function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN }) end }
    )
    map_repeatable_move(
        { key = "]e", fn = function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end },
        { key = "[e", fn = function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end }
    )
end

local function setup_autocmds()
    vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight text on yank",
        callback = function()
            vim.hl.on_yank()
        end,
    })

    vim.api.nvim_create_autocmd("BufRead", {
        desc = "Set current git branch",
        callback = function()
            vim.b.git_branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        desc = "Use *_test.go files as alternate files",
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
        desc = "Autowrite files on change",
        nested = true,
        callback = function(args)
            if args.file == "" or -- [No Name]
                vim.bo[args.buf].buftype ~= "" or
                vim.bo[args.buf].readonly
            then
                return
            end

            -- Keep trailing whitespace on the current line.
            local ws = vim.api.nvim_get_current_line():match("%s+$")
            vim.cmd("silent write")
            if ws then
                vim.api.nvim_put({ ws }, "c", true, true)
                vim.cmd("noautocmd silent write")
            end
        end,
    })
end

local function setup_user_commands()
    vim.api.nvim_create_user_command("PackUpdate", function() vim.pack.update() end, {})
end

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

    -- Automatically set argidx to the current buffer if it exists in the argument list.
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
            local pos = get_buf_pos_in_arglist(args.buf)
            if pos ~= -1 then
                -- This command does :edit %, which unloads the current buffer,
                -- rereads it, and triggers BufUnload -> BufRead -> BufEnter.
                -- However, because this happens in an autocommand, no events will be triggered.
                -- This can break plugins that rely on these events,
                -- e.g. Gitsigns reattaches on BufRead after the buffer is reloaded.
                -- Can't use nested=true because BufEnter will cause recursion.
                vim.cmd("keepjumps argument" .. tostring(pos))
                vim.cmd("doautocmd BufRead")
            end
        end,
    })

    -- Add/delete the current buffer to/from the argument list.
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

    -- Edit the previous file in the argument list.
    vim.keymap.set("n", "H", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 or vim.fn.argidx() == 0 then
            vim.cmd("last")
        else
            vim.cmd("prev")
        end
    end)

    -- Edit the next file in the argument list.
    vim.keymap.set("n", "L", function()
        if vim.fn.argc() == 0 then
            return
        elseif get_buf_pos_in_arglist(0) == -1 or vim.fn.argidx() == vim.fn.argc() - 1 then
            vim.cmd("first")
        else
            vim.cmd("next")
        end
    end)

    -- Edit the nth file in the argument list.
    for i = 1, 9 do
        vim.keymap.set("n", "g" .. tostring(i), function()
            vim.cmd("argument" .. tostring(i))
        end)
    end
end

-- https://neovim.io/doc/user/pack.html
local function setup_plugins()
    vim.pack.add({
        { src = "https://github.com/echasnovski/mini.surround" },
        { src = "https://github.com/ibhagwan/fzf-lua" },
        { src = "https://github.com/lewis6991/gitsigns.nvim" },
        { src = "https://github.com/neovim/nvim-lspconfig" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    })

    vim.api.nvim_create_autocmd("PackChanged", {
        pattern = { "nvim-treesitter" },
        callback = function(args)
            if args.data.spec.name == "nvim-treesitter" then
                require("nvim-treesitter").update(nil, { summary = true })
            end
        end,
    })
end

-- https://github.com/echasnovski/mini.surround
local function setup_surround()
    require("mini.surround").setup({
        mappings = {
            add = "gs",
            delete = "ds",
            replace = "cs",
            find = "",
            find_left = "",
            highlight = "",
        },
        respect_selection_type = true,
    })
end

-- https://github.com/lewis6991/gitsigns.nvim
local function setup_gitsigns()
    local gitsigns = require("gitsigns")

    gitsigns.setup({
        on_attach = function(buf)
            vim.keymap.set("n", "gh", gitsigns.preview_hunk_inline, { buffer = buf })
            vim.keymap.set("n", "gH", gitsigns.reset_hunk, { buffer = buf })
            map_repeatable_move(
                { key = "]c", fn = function() gitsigns.nav_hunk("next") end },
                { key = "[c", fn = function() gitsigns.nav_hunk("prev") end },
                { buffer = buf }
            )
        end,
    })

    -- Show both staged and unstaged changes.
    gitsigns.change_base("HEAD", true)
end

-- https://github.com/ibhagwan/fzf-lua
local function setup_fzf()
    local fzf = require("fzf-lua")

    fzf.setup({
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
    vim.keymap.set("n", "<Leader>\"", fzf.registers)
    vim.keymap.set("n", "<Leader>/", fzf.grep_project)
    vim.keymap.set("n", "<Leader><Leader>", fzf.resume)
    vim.keymap.set("n", "z=", fzf.spell_suggest)
end

-- https://neovim.io/doc/user/lsp.html
-- https://github.com/neovim/nvim-lspconfig
local function setup_lsp()
    vim.lsp.enable({
        "clangd",
        "gopls",
        "lua_ls",
        "ruff",
        "ty",
        "zls",
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
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
            local references = function() fzf.lsp_references({ jump1 = false, includeDeclaration = false }) end
            local implementations = function() fzf.lsp_implementations({ jump1 = false }) end

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = args.buf })
            vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = args.buf })
            vim.keymap.set("n", "<Leader>r", references, { buffer = args.buf })
            vim.keymap.set("n", "<Leader>i", implementations, { buffer = args.buf })
            vim.keymap.set("n", "<Leader>s", fzf.lsp_document_symbols, { buffer = args.buf })
            vim.keymap.set("n", "<Leader>S", fzf.lsp_live_workspace_symbols, { buffer = args.buf })
        end,
    })

    -- https://luals.github.io/wiki/settings
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
    vim.lsp.config("lua_ls", {
        on_init = function(client)
            local path = client.workspace_folders[1].name
            if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
                return
            end
            client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                runtime = { version = "LuaJIT" },
                workspace = {
                    checkThirdParty = false,
                    library = { vim.env.VIMRUNTIME },
                },
            })
        end,
        settings = { Lua = {} },
    })
end

-- https://neovim.io/doc/user/treesitter.html
-- https://github.com/nvim-treesitter/nvim-treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
-- https://github.com/nvim-treesitter/nvim-treesitter-context
local function setup_treesitter()
    local treesitter = require("nvim-treesitter")

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            local lang = assert(vim.treesitter.language.get_lang(args.match))

            local start = function()
                vim.treesitter.start(args.buf, lang)
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end

            if vim.treesitter.language.add(lang) then
                start()
            elseif vim.tbl_contains(treesitter.get_available(), lang) then
                treesitter.install(lang):await(start)
            end
        end,
    })

    require("nvim-treesitter-textobjects").setup({
        select = {
            include_surrounding_whitespace = true,
        },
        move = {
            set_jumps = true,
        },
    })

    local select = require("nvim-treesitter-textobjects.select").select_textobject
    vim.keymap.set({ "x", "o" }, "it", function() select("@class.inner", "textobjects") end)
    vim.keymap.set({ "x", "o" }, "at", function() select("@class.outer", "textobjects") end)
    vim.keymap.set({ "x", "o" }, "if", function() select("@function.inner", "textobjects") end)
    vim.keymap.set({ "x", "o" }, "af", function() select("@function.outer", "textobjects") end)
    vim.keymap.set({ "x", "o" }, "ia", function() select("@parameter.inner", "textobjects") end)
    vim.keymap.set({ "x", "o" }, "aa", function() select("@parameter.outer", "textobjects") end)

    local goto_next = require("nvim-treesitter-textobjects.move").goto_next_start
    local goto_prev = require("nvim-treesitter-textobjects.move").goto_previous_start
    map_repeatable_move(
        { key = "]]", fn = function() goto_next({ "@class.outer", "@function.outer" }, "textobjects") end },
        { key = "[[", fn = function() goto_prev({ "@class.outer", "@function.outer" }, "textobjects") end }
    )
    map_repeatable_move(
        { key = "]t", fn = function() goto_next("@class.outer", "textobjects") end },
        { key = "[t", fn = function() goto_prev("@class.outer", "textobjects") end }
    )
    map_repeatable_move(
        { key = "]f", fn = function() goto_next("@function.outer", "textobjects") end },
        { key = "[f", fn = function() goto_prev("@function.outer", "textobjects") end }
    )
    map_repeatable_move(
        { key = "]a", fn = function() goto_next("@parameter.inner", "textobjects") end },
        { key = "[a", fn = function() goto_prev("@parameter.inner", "textobjects") end }
    )

    local goto_context = require("treesitter-context").go_to_context
    vim.keymap.set("n", "gC", function() goto_context(vim.v.count1) end)
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
        "%F %m", -- Filepath and modified flag.
        "%=",    -- Separation point.
        "%S",    -- Pending operator or number of selected characters.
        macro_recording(),
        search_count(),
        join_non_empty({
            with_hl("DiagnosticSignError", diagnostic_count(vim.diagnostic.severity.ERROR)),
            with_hl("DiagnosticSignWarn", diagnostic_count(vim.diagnostic.severity.WARN)),
            with_hl("DiagnosticSignInfo", diagnostic_count(vim.diagnostic.severity.INFO)),
            with_hl("DiagnosticSignHint", diagnostic_count(vim.diagnostic.severity.HINT)),
        }, " "),
        attached_lsp(),
        "%l/%L (%p%%)", -- Line number / total lines (file progress in %).
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
setup_surround()
setup_gitsigns()
setup_fzf()
setup_lsp()
setup_treesitter()
