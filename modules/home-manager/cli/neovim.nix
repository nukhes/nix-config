{
  pkgs,
  ...
}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      lualine-nvim
      nvim-web-devicons
      nvim-lspconfig
      nvim-tree-lua
      vim-lastplace
      mini-nvim
    ];

    extraPackages = with pkgs; [
      lua-language-server
      pyright
      typescript-language-server
      nil
    ];

    initLua = ''
      vim.opt.termguicolors = true
      vim.cmd("syntax on")
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("mini.pairs").setup()

      require("nvim-tree").setup({
        view = {
          width = 30,
          side = "left",
        },
      })

      require("lualine").setup({
        options = {
          icons_enabled = true,
          component_separators = "|",
          section_separators = "",
        }
      })

      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"
      vim.opt.clipboard = "unnamedplus"
      vim.opt.hidden = true
      vim.opt.history = 1000
      vim.opt.encoding = "utf-8"
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.undofile = true
      vim.opt.scrolloff = 8

      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.autoindent = true
      vim.opt.smartindent = true

      vim.opt.hlsearch = true
      vim.opt.incsearch = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true

      vim.g.mapleader = " "

      local keymap = vim.keymap.set
      local opts = { silent = true }

      keymap("n", "<leader><CR>", ":noh<CR>", opts)
      keymap("n", "<leader>w", ":w<CR>", opts)
      keymap("n", "<leader>q", ":q<CR>", opts)

      keymap("n", "<C-h>", "<C-w>h", opts)
      keymap("n", "<C-j>", "<C-w>j", opts)
      keymap("n", "<C-k>", "<C-w>k", opts)
      keymap("n", "<C-l>", "<C-w>l", opts)

      keymap("n", "<S-l>", ":bnext<CR>", opts)
      keymap("n", "<S-h>", ":bprevious<CR>", opts)
      keymap("n", "<C-b>", ":NvimTreeToggle<CR>", opts)

      -- Configuração de LSP
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('pyright')
      vim.lsp.enable('ts_ls')
      vim.lsp.enable('nil_ls')
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }

          -- gd -> Go to Definition
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)

          -- K -> Hover Documentation
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

          -- Leader (Spacebar) + r + n -> Rename this keyword
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        end,
      })
    '';
  };
}
