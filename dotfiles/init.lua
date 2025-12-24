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
        skip_picker_for_single_result = true, -- Jump directly if only one match
      },
      disable_maps = false, 
    },
    config = function(_, opts)
      require("cscope_maps").setup(opts)
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

-- Vimdiff helper (Vimscript embedded in Lua)
vim.cmd([[
function! Vimdiff()
    let lines = getline(0,'$')
    let la = []
    let lb = []
    for line in lines
        if line[0] == '-'
            call add(la, ' ' . line[1:])
        elseif line[0] == '+'
            call add(lb, ' ' . line[1:])
        else
            call add(la, line)
            call add(lb, line)
        endif
    endfor
    tabnew
    set bt=nofile
    vertical new
    set bt=nofile
    call append(0, la)
    diffthis
    exe "normal \<C-W>l"
    call append(0, lb)
    diffthis
    call mark#ClearAll()
    call mark#DoMark('^diff \-\-.*$')
    "call ResetDiffChar(0)
    call feedkeys("gg")
endfunction
]])

local map = vim.keymap.set
map("n", "<localleader>v1", "<cmd>Git diff<CR><cmd>call Vimdiff()<CR>", { silent = true })
map("n", "<localleader>v2", "<cmd>call Vimdiff()<CR>", { silent = true })
map("n", "<localleader>v3", "<cmd>tabclose<bar>bdelete<CR>", { silent = true })
map("n", "<space>r1", "<cmd>silent! lgrep <cword> % | lopen<cr>")
map("n", "<space>r2", "<cmd>silent! lgrep <cword> %:h | lopen<cr>")
map("n", "<space>r3", "<cmd>silent! lgrep <cword> . | lopen<cr>")
-- visual selection
map("v", "<space>r1", "y<cmd>silent! lgrep <C-r>\" % | lopen<cr>")
map("v", "<space>r2", "y<cmd>silent! lgrep <C-r>\" %:h | lopen<cr>")
map("v", "<space>r3", "y<cmd>silent! lgrep <C-r>\" . | lopen<cr>")
-- tag search
map("n", "<space>r4", "<cmd>silent! lgrep #<cword> %:h | lopen<cr>")

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
