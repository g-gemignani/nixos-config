# What is installed system-wide, plus the modules that wrap a package.
{ pkgs, ... }:

{
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    p7zip
    zip
    unzip
    wget
    git
    gh
    glab
    pinentry-curses
    htop
    tree
    silver-searcher
    # Chrome crashes on Wayland with GTK4. GTK3 is stable.
    (google-chrome.override { commandLineArgs = "--gtk-version=3"; })
    flameshot
    dnsutils
    rar
    unar
    # coding
    # Pillow is for the viewer mod, which decodes images with python3 -I
    (python3.withPackages (ps: [ ps.pillow ]))
    uv
    poetry
    cargo
    gcc
    pkg-config
    code-cursor
    claude-code
    networkmanagerapplet
    wdisplays
    blueman
    # sops for encrypting/decrypting secrets stored in the repo
    sops
    lsof
    # office
    onlyoffice-desktopeditors
    xournalpp
  ];

  hardware.graphics.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
