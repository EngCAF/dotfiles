-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = "\\"
vim.g.maplocalleader = " "
vim.o.termguicolors = true
vim.o.grepprg = "rg --vimgrep --smart-case"
vim.o.grepformat = "%f:%l:%c:%m"

vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  -- Sensible defaults
  'tpope/vim-sensible',

  -- Colorschemes
  'junegunn/seoul256.vim',
  'flazz/vim-colorschemes',
  {
    'xolox/vim-colorscheme-switcher',
    dependencies = { 'xolox/vim-misc' },
    config = function()
      vim.api.nvim_set_keymap('n', 'gc', ':RandomColorScheme<CR>', { noremap = true })
    end
  },

  -- Snippets
  'rafamadriz/friendly-snippets',

  -- Git
  'tpope/vim-fugitive',

  -- General utilities
  'tpope/vim-surround',
  'Chiel92/vim-autoformat',
  'preservim/nerdtree',

  -- Marks
  {
    'inkarkat/vim-mark',
    dependencies = {
      "inkarkat/vim-ingo-library",
    },
    init = function()
      vim.g.mwDefaultHighlightingPalette = "maximum"
    end,
    config = function()
      local map = vim.keymap.set

      map('n', '<SPACE>mc', ':MarkClear<CR>', { silent = true })
      map('n', '<SPACE>mr', '<Plug>MarkRegex', { remap = true })
      map('n', '<SPACE>mi', [[:Mark <C-R><C-W><CR>]], { silent = true })
      map('v', '<SPACE>mi', [[y:Mark <C-R>"<CR>]], { silent = true })
      map('n', '<SPACE>mf', [[<cmd>call mark#DoMark('^\s\(--\|<Bar>++\)\s.*$')<CR>]], { silent = true })
    end
  },

  -- FZF
  { 'junegunn/fzf', build = "fzf#install()" },

  -- UI
  'itchyny/lightline.vim',

  -- LSP and completion
  'neovim/nvim-lspconfig',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'L3MON4D3/LuaSnip',
  'saadparwaiz1/cmp_luasnip',
  {
    "folke/flash.nvim",
    event = "VeryLazy", -- or remove this line to load immediately
    opts = {
      char = { enabled = true },
      search = { enabled = true },
    },
    keys = {
      -- Disable , and ; globally so they do nothing
      { ",", "<Nop>", mode = { "n", "x", "o" }, desc = "Disabled" },
      { ";", "<Nop>", mode = { "n", "x", "o" }, desc = "Disabled" },
    },
    config = function(_, opts) --[[ ... ]]--
      require("flash").setup(opts)

      vim.keymap.set({ "n", "x", "o" }, "f", function()
        require("flash").jump({
          search = {
            mode = "char",
            forward = true,
            backward = true,
            multi_window = true,
          },
        })
      end, { desc = "Flash char (both directions)" })
    end,
  },
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "nvim-mini/mini.icons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostics disable: missing-fields
    opts = {},
    keys = {
      {
        "<localleader>l",
        function()
          require("fzf-lua").builtin()
        end,
        desc = "FzfLua (CocList-like)",
      },
      {
        "gm",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "FzfLua old files (MRU)",
      },
      {
        "go",
        function()
          require("fzf-lua").files()
        end,
        desc = "FzfLua files in current dir",
      },
      {
        "gw",
        function()
          require("fzf-lua").tags_grep_cword()
        end,
        desc = "FzfLua grep cword",
      },
    },
    ---@diagnostics enable: missing-fields
  },
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    event = "VeryLazy",
    version = "2.*",
    opts = {
      hint = "floating-big-letter",
      filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        bo = {
          filetype = { "neo-tree", "neo-tree-popup", "notify" },
          buftype = {},
        },
      },
    },
    keys = {
      {
        "<leader>w",
        function()
          local picked = require("window-picker").pick_window()
          if picked then
            vim.api.nvim_set_current_win(picked)
          end
        end,
        desc = "Pick a window",
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 60,
      direction = "vertical",
      persist_size = true,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
    },
    keys = {
      {
        "<leader>tv",
        "<cmd>ToggleTerm direction=vertical size=60<CR>",
        desc = "Toggle vertical terminal",
        mode = "n",
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local function toggle_term_mode()
        local m = vim.fn.mode()
        if m == "t" then
          -- terminal insert -> terminal normal
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
            "n",
            false
          )
        else
          -- terminal normal (or normal) -> terminal insert
          vim.cmd("startinsert")
        end
      end

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = function(ev)
          local b = ev.buf
          -- works in BOTH terminal-insert and terminal-normal
          vim.keymap.set("t", "<C-,>", toggle_term_mode, { buffer = b, silent = true, desc = "Toggle terminal insert/normal" })
          vim.keymap.set("n", "<C-,>", toggle_term_mode, { buffer = b, silent = true, desc = "Toggle terminal insert/normal" })
        end,
      })
    end,
  },
  {
    "declancm/windex.nvim",
    keys = {
      {
        "<leader>z",
        function()
          require("windex").toggle_nvim_maximize()
        end,
        desc = "Maximize/restore window",
      },
    },
  },
  {
    "sindrets/winshift.nvim",
    cmd = "WinShift",
    config = function()
      require("winshift").setup({
        highlight_moving_win = true,
        focused_hl_group = "Visual",
        moving_win_options = {
          wrap = false,
          cursorline = false,
          cursorcolumn = false,
          colorcolumn = "",
        },
        keymaps = {
          disable_defaults = false,
          win_move_mode = {
            ["h"] = "left",
            ["j"] = "down",
            ["k"] = "up",
            ["l"] = "right",
            ["H"] = "far_left",
            ["J"] = "far_down",
            ["K"] = "far_up",
            ["L"] = "far_right",
            ["<left>"] = "left",
            ["<down>"] = "down",
            ["<up>"] = "up",
            ["<right>"] = "right",
            ["<S-left>"] = "far_left",
            ["<S-down>"] = "far_down",
            ["<S-up>"] = "far_up",
            ["<S-right>"] = "far_right",
          },
        },
      })

      -- normal-mode mapping (must be outside setup)
      vim.keymap.set(
        "n",
        "<C-w>x",
        "<cmd>WinShift swap<CR>",
        { silent = true, desc = "WinShift swap" }
      )
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
          -- Configuration here, or leave empty to use defaults
      })
    end
  },
  {
    "gregorias/coerce.nvim",
    dependencies = {
          "gregorias/coop.nvim",
    },
    tag = 'v4.1.0',
    config = true,
  },
  {
      'windwp/nvim-autopairs',
      event = "InsertEnter",
      config = true
      -- use opts = {} for passing setup options
      -- this is equivalent to setup({}) function
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,          -- README: does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- Enable highlighting per filetype (example: markdown)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function() vim.treesitter.start() end,
      })

      -- Folding (Neovim-provided)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
      })
    end,
  },
  {
    "dhananjaylatkar/cscope_maps.nvim",
    dependencies = {
      "ibhagwan/fzf-lua", -- Use fzf-lua as the UI provider
    },
    opts = {
      skip_input_prompt = true,
      cscope = {
        exec = "gtags-cscope", -- Path to executable
        db_file = "GTAGS",     -- Look for gtags database
        picker = "fzf-lua",    -- Set fzf-lua as the result filter/picker
        skip_picker_for_single_result = false, -- Jump directly if only one match
      },
      disable_maps = false, 
    },
    config = function(_, opts)
      require("cscope_maps").setup(opts)
    end,
  },
  {
    "stevearc/aerial.nvim",
    opts = {},
    config = function()
      require("aerial").setup({
        -- Optional: Set keymaps to toggle aerial
        on_attach = function(bufnr)
          -- Jump forwards/backwards with '{' and '}'
          vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
      })
      -- You probably also want to set a keymap to toggle aerial
      vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>")
    end,
  },
  {
    "rmagatti/auto-session",
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      -- log_level = 'debug',
    },
  },
  {
    "preservim/tagbar",
    ft = { "autohotkey" },
    cmd = "TagbarToggle",
    keys = { { "<F8>", "<cmd>TagbarToggle<CR>", desc = "Tagbar" } },
    config = function()
      vim.g.tagbar_type_autohotkey = {
        ctagstype = "AutoHotkey", -- MUST match --langdef=AutoHotkey
        kinds = {
          "c:Classes",
          "f:Functions",
          "k:Hotkeys",
          "s:Hotstrings",
          "l:Labels",
          "v:Variables",
        },
        sort = 0,
      }
    end,
  },
})


-- LSP: mason + lspconfig
require("mason").setup()

require("mason-lspconfig").setup({
  -- put servers you want here
  ensure_installed = { "lua_ls", "pyright", "clangd" },
})

-- nvim-cmp capabilities -> LSP completion
local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
})

-- enable servers (mason-lspconfig may auto-enable; this is safe/explicit)
vim.lsp.enable({ "lua_ls", "pyright", "clangd" })

-- Completion: nvim-cmp + LuaSnip
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  },
})

-- Other settings
vim.opt.mouse = 'a'
vim.opt.hls = true
vim.opt.ignorecase = true
vim.opt.history = 10000
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
vim.opt.laststatus = 2
vim.opt.signcolumn = 'no'
vim.opt.diffopt:append('internal,algorithm:patience')
vim.opt.clipboard:append('unnamed,unnamedplus')
vim.cmd('color github')


local function git_combined_diff(opts)
    local user_args = opts.args

    -- 1. Get the list of files using the exact string the user provided
    local list_cmd = string.format("git diff --name-only %s", user_args)
    local handle = io.popen(list_cmd)
    if not handle then return end
    local files_str = handle:read("*a")
    handle:close()

    local files = {}
    for file in files_str:gmatch("[^\r\n]+") do table.insert(files, file) end
    if #files == 0 then print("No changes found."); return end

    -- 2. Resolve the "Left" and "Right" sides using Git's logic
    -- We use 'git rev-parse' to figure out what the user meant
    local left_ref = "HEAD"
    local right_ref = "" -- Default to working directory (disk)

    -- Detect '--cached' or '--staged'
    local is_cached = user_args:find("--cached") or user_args:find("--staged")

    -- Split args to find the revision part (the part before '--' if present)
    local rev_part = user_args:match("^(.-)%s%-%-") or user_args

    if rev_part:find("%.%.%.") then
        left_ref = vim.fn.system(string.format("git merge-base %s", rev_part:gsub("%.%.%.", " "))):gsub("%s+", "")
        right_ref = rev_part:match("%.%.%.([^%s]+)")
    elseif rev_part:find("%.%.") then
        left_ref = rev_part:match("([^%.%s]+)%.%.")
        right_ref = rev_part:match("%.%.([^%.%s]+)")
    elseif is_cached then
        left_ref = "HEAD"
        right_ref = ":0" -- The Index
    elseif rev_part ~= "" and not rev_part:find("^-") then
        -- Handle single ref like 'HEAD~1' or 'master'
        local first_word = rev_part:match("^(%S+)")
        -- Verify if it's a valid git object
        local verify = os.execute(string.format("git rev-parse --verify %s >/dev/null 2>&1", first_word))
        if verify == 0 then
            left_ref = first_word
            right_ref = "" -- Compare against disk
        end
    end

    -- 3. Create UI
    vim.cmd("tabnew")
    local left_buf = vim.api.nvim_get_current_buf()
    vim.cmd("rightbelow vnew")
    local right_buf = vim.api.nvim_get_current_buf()

    local left_lines, right_lines = {}, {}

    local function get_git_content(ref, file)
        if ref == "" then -- Read from disk
            local f = io.open(file, "r")
            if not f then return {"<File deleted or not found>"} end
            local content = {}
            for line in f:lines() do table.insert(content, line) end
            f:close()
            return content
        end
        local h = io.popen(string.format("git show %s:%s 2>/dev/null", ref, file))
        local content = {}
        if h then for line in h:lines() do table.insert(content, line) end h:close() end
        return content
    end

    -- 4. Build Content
    for _, file in ipairs(files) do
        local header = string.format("--- FILE: %s ---", file)
        table.insert(left_lines, header)
        table.insert(left_lines, string.rep(">", #header))
        table.insert(right_lines, header)
        table.insert(right_lines, string.rep("<", #header))

        local l_cont = get_git_content(left_ref, file)
        local r_cont = get_git_content(right_ref, file)

        for _, l in ipairs(l_cont) do table.insert(left_lines, l) end
        for _, r in ipairs(r_cont) do table.insert(right_lines, r) end
    end

    -- 5. Finalize Buffers
    local function setup_buf(buf, lines, name)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].filetype = "nofile", "wipe", "diff"
        pcall(vim.api.nvim_buf_set_name, buf, name .. " [" .. (user_args ~= "" and user_args or "WD") .. "]")
        vim.cmd("highlight CombinedDiffHeader guifg=#000000 guibg=#EBCB8B gui=bold")
        vim.api.nvim_buf_call(buf, function()
            vim.fn.matchadd("CombinedDiffHeader", "^--- FILE:.*")
            vim.fn.matchadd("CombinedDiffHeader", "^>>>>*")
            vim.fn.matchadd("CombinedDiffHeader", "^<<<<*")
        end)
    end

    setup_buf(left_buf, left_lines, "OLD")
    setup_buf(right_buf, right_lines, "NEW")
    vim.cmd("windo diffthis")
end

vim.api.nvim_create_user_command('GdiffCombined', git_combined_diff, { nargs = '*' })

vim.keymap.set("n", "\\gd", function()
  -- opens ":" command-line with the command prefilled, cursor at end
  vim.fn.feedkeys(":GdiffCombined ", "n")
end, { noremap = true, silent = true, desc = "Prompt :GdiffCombined [arg]" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<localleader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<localleader>ca", vim.lsp.buf.code_action, opts)
  end,
})

local function set_tmux_title()
  if not os.getenv("TMUX") then return end

  local file = vim.fn.expand("%:t")
  if file == "" then file = "[No Name]" end

  vim.fn.system({
    "tmux",
    "select-pane",
    "-T",
    file
  })
end

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufWinEnter", "BufFilePost" },
  {
    callback = set_tmux_title,
  }
)

vim.keymap.set('n', ',x', ':tabclose<CR>', { noremap = true, silent = true, desc = 'Close current tab' })
vim.keymap.set("n", "<space>r1", "<cmd>silent! lgrep <cword> % | lopen<cr>")
vim.keymap.set("n", "<space>r2", "<cmd>silent! lgrep <cword> %:h | lopen<cr>")
vim.keymap.set("n", "<space>r3", "<cmd>silent! lgrep <cword> . | lopen<cr>")
vim.keymap.set("v", "<space>r1", "y<cmd>silent! lgrep <C-r>\" % | lopen<cr>")
vim.keymap.set("v", "<space>r2", "y<cmd>silent! lgrep <C-r>\" %:h | lopen<cr>")
vim.keymap.set("v", "<space>r3", "y<cmd>silent! lgrep <C-r>\" . | lopen<cr>")
vim.keymap.set("n", "<space>r4", "<cmd>silent! lgrep #<cword> %:h | lopen<cr>")
