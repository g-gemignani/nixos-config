{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      ale
      nvim-autopairs
      vim-lastplace
      vim-nix
      dracula-vim
    ];

    extraLuaConfig = ''
      -- ALE settings
      vim.g.ale_fix_on_save = 1
      vim.g.ale_fixers = {
          nix = { "alejandra" },
          python = { "black", "isort" },
      }

      -- Options
      vim.opt.background = "light"
      vim.opt.copyindent = true
      vim.opt.clipboard = "unnamedplus"
      vim.opt.expandtab = true
      vim.opt.hidden = true
      vim.opt.history = 7000
      vim.opt.ignorecase = true
      vim.opt.modeline = true
      vim.opt.mouse = "n"
      vim.opt.mousefocus = true
      vim.opt.mousehide = true
      vim.opt.mousemodel = "extend"
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.shiftwidth = 4
      vim.opt.smartcase = true
      vim.opt.tabstop = 4
      vim.opt.undodir = vim.fn.stdpath("config") .. "/undodir//"
      vim.opt.undofile = true

      -- Theme
      vim.cmd.colorscheme("dracula")
    '';
  };
}
