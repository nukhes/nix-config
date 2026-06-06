{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      lualine-nvim
      nvim-web-devicons
      vim-lastplace
      mini-nvim
    ];

    initLua = ''
      vim.opt.termguicolors = true
      vim.cmd("syntax on")

      require("mini.pairs").setup()

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

      vim.opt.tabstop = 4
      vim.opt.shiftwidth = 4
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
    '';
  };
}
