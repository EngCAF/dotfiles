local calendar_creds = vim.fn.expand('~/.cache/calendar.vim/credentials.vim')
if vim.fn.filereadable(calendar_creds) == 1 then
  vim.cmd('source ' .. vim.fn.fnameescape(calendar_creds))
end
vim.g.python3_host_prog = 'python3'
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

vim.opt.wrap = true       -- Enable visual wrapping
vim.opt.linebreak = true  -- Wrap at words, not characters
vim.opt.list = false
-- Keep modes visually distinct in tmux: a steady Normal-mode block and fast,
-- blinking blocks in Insert and terminal modes. TUI cursor colors come from
-- the terminal.
vim.opt.guicursor = "n-v-c:block,i-ci-ve:block-blinkwait150-blinkon250-blinkoff200,r-cr:hor20,o:hor50,t:block-blinkwait0-blinkon250-blinkoff200"
vim.opt.shada = "!,'100,<50,s10,h" -- Limit ShaDa file marks/oldfiles history to 100 entries
-- Automatically resolve symlinks to canonical paths for Git integration (Fugitive, gitsigns, etc.)
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("ResolveSymlinks", { clear = true }),
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" then return end
    local realpath = (vim.uv or vim.loop).fs_realpath(path)
    if realpath and realpath ~= path then
      vim.cmd("file " .. vim.fn.fnameescape(realpath))
    end
  end,
})

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
  'MenkeTechnologies/VimColorSchemes',
  {
    lazy = false,
    priority = 1000,
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
  {
      "othree/eregex.vim",
      -- Load the plugin immediately so the commands are ready
      lazy = false,
      config = function()
        -- Optional: Set default options for eregex here
        -- Example: Force case-insensitive search by default
        vim.g.eregex_force_case = 0
      end
  },

  -- General utilities
  'tpope/vim-surround',
  { 'Chiel92/vim-autoformat', cmd = "Autoformat" },
  {
      'raghur/vim-ghost',
      build = ':GhostInstall', -- This runs the python setup script
      lazy = false,            -- Load immediately so it can listen to the browser
  },
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
  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "clangd" },
      })

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

      vim.lsp.enable({ "lua_ls", "pyright", "clangd" })
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
    },
    config = function()
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
    end,
  },
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
          require("fzf-lua").oldfiles({
            cwd_only = false,
            include_current_session = true,  -- Add this line
            git_icons = false,
            stat_file = false,
          })
        end,
        desc = "FzfLua old files (MRU) + Buffers",
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
      {
        "gl",
        function()
          local file = vim.fn.expand("%")
          if file == "" then return end
          require("fzf-lua").fzf_exec("global -x -f " .. vim.fn.shellescape(file) .. " | awk '{printf \"%s:%s:%s\\n\", $3, $2, substr($0, index($0,$4))}'", {
            prompt = "Document Symbols> ",
            fn_transform = function(x)
              return require("fzf-lua.make_entry").file(x, { file_icons = true, color_icons = true })
            end,
            actions = require("fzf-lua").defaults.actions.files,
            previewer = "builtin",
          })
        end,
        desc = "GTAGS Document Symbols",
      },
      {
        "gL",
        function()
          require("fzf-lua").fzf_exec("global -x '.*' | awk '{printf \"%s:%s:%s\\n\", $3, $2, substr($0, index($0,$4))}'", {
            prompt = "Workspace Symbols> ",
            fn_transform = function(x)
              return require("fzf-lua.make_entry").file(x, { file_icons = true, color_icons = true })
            end,
            actions = require("fzf-lua").defaults.actions.files,
            previewer = "builtin",
          })
        end,
        desc = "GTAGS Workspace Symbols",
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
      shade_terminals = false,
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
      'itchyny/calendar.vim',
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
        callback = function()
          vim.treesitter.start()
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
      })
    end,
  },
  {
    "dhananjaylatkar/cscope_maps.nvim",
    event = "VeryLazy",
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
      db_build_cmd = {
        script = "sh",
        args = { "-c", "find . -type f \\( -name '*.[ch]' -o -name '*.cpp' -o -name '*.hpp' -o -name '*.cc' -o -name '*.cxx' -o -name '*.hh' \\) > gtags.files && gtags -i -f gtags.files" },
      },
      disable_maps = false,
    },
    config = function(_, opts)
      require("cscope_maps").setup(opts)
    end,
  },
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNext", "AerialPrev" },
    keys = {
      { "<leader>a", "<cmd>AerialToggle!<CR>", desc = "Aerial Toggle" },
    },
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
  {
    'renerocksai/telekasten.nvim',
    cmd = { "Telekasten" },
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim', -- Telescope's required utility library
        'renerocksai/calendar-vim', -- Use this specific fork instead
    },
    opts = {
        home = vim.fn.expand("~/shared/downloads/md/nvim/"),
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- Optional: adds file icons
      "s1n7ax/nvim-window-picker",
    },
    config = function()
      -- Initialize the plugin
      require("nvim-tree").setup({
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30, -- Set the sidebar width
        },
        filters = {
          git_ignored = false,
        },
        actions = {
          open_file = {
            window_picker = {
              enable = true,
              picker = require("window-picker").pick_window,
            },
          },
        },
      })

      -- Create your shortcut key to open it (Space + e)
      vim.keymap.set('n', '<space>e', ':NvimTreeToggle<CR>', { silent = true })
    end,
  }
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

    local buf_path = vim.api.nvim_buf_get_name(0)
    local buf_dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
    local git_root = vim.trim(vim.fn.system(string.format("git -C %s rev-parse --show-toplevel", vim.fn.shellescape(buf_dir))))

    if vim.v.shell_error ~= 0 or git_root == "" then
      local fallback_dir = (vim.fn.exists("*FugitiveWorkTree") == 1 and vim.fn.FugitiveWorkTree() ~= "")
        and vim.fn.FugitiveWorkTree()
        or vim.fn.getcwd()
      git_root = vim.trim(vim.fn.system(string.format("git -C %s rev-parse --show-toplevel", vim.fn.shellescape(fallback_dir))))
      if vim.v.shell_error ~= 0 or git_root == "" then
        print("Not a git repository")
        return
      end
    end

    local git_cmd_prefix = string.format("git -C %s ", vim.fn.shellescape(git_root))

    -- 1. Get the list of files using the exact string the user provided
    local list_cmd = string.format("%sdiff --name-only %s", git_cmd_prefix, user_args)
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
        left_ref = vim.fn.system(string.format("%smerge-base %s", git_cmd_prefix, rev_part:gsub("%.%.%.", " "))):gsub("%s+", "")
        right_ref = rev_part:match("%.%.%.([^%s]+)")
    elseif rev_part:find("%.%.") then
        left_ref = rev_part:match("([^%.%s]+)%.%.")
        right_ref = rev_part:match("%.%.([^%.%s]+)")
    elseif is_cached then
        left_ref = "HEAD"
        right_ref = ":0" -- The Index
    elseif rev_part ~= "" and not rev_part:find("^-") then
      -- Handle two refs like 'commit1 commit2'
      local first_word, second_word = rev_part:match("^(%S+)%s+(%S+)")
      if first_word and second_word then
        local verify1 = os.execute(string.format("%srev-parse --verify %s >/dev/null 2>&1", git_cmd_prefix, first_word))
        local verify2 = os.execute(string.format("%srev-parse --verify %s >/dev/null 2>&1", git_cmd_prefix, second_word))
        if verify1 == 0 and verify2 == 0 then
          left_ref = first_word
          right_ref = second_word
        end
      else
        -- Handle single ref like 'HEAD~1' or 'master'
        local first_word = rev_part:match("^(%S+)")
        -- Verify if it's a valid git object
        local verify = os.execute(string.format("%srev-parse --verify %s >/dev/null 2>&1", git_cmd_prefix, first_word))
        if verify == 0 then
          left_ref = first_word
          right_ref = "" -- Compare against disk
        end
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
            local f = io.open(git_root .. "/" .. file, "r")
            if not f then return {"<File deleted or not found>"} end
            local content = {}
            for line in f:lines() do table.insert(content, line) end
            f:close()
            return content
        end
        local h = io.popen(string.format("%sshow %s:%s 2>/dev/null", git_cmd_prefix, ref, file))
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
        vim.bo[buf].swapfile = false
        vim.bo[buf].undofile = false
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

vim.keymap.set("n", "gf1", ":GdiffCombined<CR>", {
  noremap = true,
  silent = true,
  desc = "Execute :GdiffCombined directly"
})

vim.keymap.set("n", "gf2", ":GdiffCombined <C-R><C-W>~1..<C-R><C-W><CR>", {
  noremap = true,
  silent = false,
  desc = "GdiffCombined current_file~ then complete and execute"
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function(ev)
    local function open_tab_diff()
      -- Trigger Fugitive's buffer mapping 'O' (open in tab) then run :Gdiffsplit!
      local keys = vim.api.nvim_replace_termcodes("O:Gdiffsplit!<CR>", true, false, true)
      vim.api.nvim_feedkeys(keys, "m", false)
    end

    vim.keymap.set("n", "dt", open_tab_diff, { buffer = ev.buf, silent = true, desc = "Open side-by-side diff in new tab" })
  end,
})

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

  vim.system({
    "tmux",
    "select-pane",
    "-T",
    file
  }, { detach = true })
end

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufFilePost" },
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

vim.api.nvim_create_user_command('CsUpdateCurrent', function()
  local current_file = vim.fn.expand('%:p')
  local current_filename = vim.fn.expand('%:t') -- Capture filename before async

  vim.system({ 'gtags', '--single-update', current_file }, { text = true }, function(obj)
    -- Use vim.schedule to safely call vim functions from async context
    vim.schedule(function()
      if obj.code == 0 then
        print('Updated GTAGS for: ' .. current_filename)
      else
        print('Failed to update GTAGS: ' .. (obj.stderr or 'unknown error'))
      end
    end)
  end)
end, {})

vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Terminal: normal mode" })

vim.keymap.set("n", "gx", function()
  local url = vim.fn.expand("<cfile>")
  if url:match("https?://") then
    -- jobstart launches the process in the background and doesn't wait
    vim.fn.jobstart({ "xdg-open", url }, { detach = true })
  end
end, { desc = "Async open link" })

vim.keymap.set('n', '<space>t', function()
  local home = vim.fn.expand("~/shared/downloads/md/nvim/")
  require('telescope.builtin').live_grep({
    cwd = home,
    default_text = "@"
  })
end, { desc = "Search @tags in Telekasten" })

vim.keymap.set('n', '<space>f', '<C-w>gf', { desc = 'Open file under cursor in new tab' })
vim.keymap.set('n', '<leader>p', [[:let @+ = expand('%:p')<CR>]], { silent = true })

-- Set the ANSI palette used when a terminal opens. Existing terminal buffers
-- retain their palette, so open a new terminal after changing schemes.
local function set_terminal_palette()
  local function color(group, attribute, fallback)
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    return highlight[attribute] and string.format("#%06x", highlight[attribute]) or fallback
  end

  local background = color("Normal", "bg", "#1e1e1e")
  local foreground = color("Normal", "fg", "#d4d4d4")
  local red = color("DiagnosticError", "fg", color("ErrorMsg", "fg", "#e06c75"))
  local green = color("DiagnosticOk", "fg", color("String", "fg", "#98c379"))
  local yellow = color("DiagnosticWarn", "fg", color("WarningMsg", "fg", "#e5c07b"))
  local blue = color("DiagnosticInfo", "fg", color("Function", "fg", "#61afef"))
  local magenta = color("DiagnosticHint", "fg", color("Statement", "fg", "#c678dd"))
  local cyan = color("Special", "fg", color("Constant", "fg", "#56b6c2"))
  local gray = color("Comment", "fg", "#5c6370")
  local palette = {
    background, red, green, yellow, blue, magenta, cyan, foreground,
    gray, red, green, yellow, blue, magenta, cyan, foreground,
  }

  for index, value in ipairs(palette) do
    vim.g["terminal_color_" .. (index - 1)] = value
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("TerminalPalette", { clear = true }),
  callback = set_terminal_palette,
})
set_terminal_palette()

vim.keymap.set('n', '<leader>z', function()
  if vim.t.buffer_maximized then
    vim.cmd('tabclose')
    return
  end

  vim.cmd('tabedit %')
  vim.t.buffer_maximized = true
end, { desc = 'Toggle current buffer maximization' })

vim.api.nvim_create_user_command('Codex', function()
    local codex_bin = vim.fn.exepath('codex')
    if codex_bin == '' then
      codex_bin = 'codex'
    end
    vim.cmd('terminal env FORCE_COLOR=1 ' .. vim.fn.fnameescape(codex_bin))
end, {})

vim.api.nvim_create_user_command('Agy', function(opts)
    local agy_bin = vim.fn.exepath('agy')
    if agy_bin == '' then
      agy_bin = 'agy'
    end
    local cmd = 'terminal env FORCE_COLOR=1 ' .. vim.fn.fnameescape(agy_bin)
    if opts.args and opts.args ~= '' then
      cmd = cmd .. ' ' .. opts.args
    end
    vim.cmd(cmd)
end, { nargs = '*' })
