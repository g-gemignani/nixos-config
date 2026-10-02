# Display manager, the two sessions, sound, input, fonts and portals.
{ pkgs, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # Enable the X11 windowing system (required base even for Wayland/Hyprland).
  services.xserver.enable = true;

  # Expose both GNOME and Hyprland in the greeter.
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "gnome";
  services.desktopManager.gnome.enable = true;

  # Enable Hyprland.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true; # For X11 app compatibility.
  };

  # Keep the greeter and Wayland session on the same keyboard layouts.
  services.xserver.xkb.layout = "de,us";
  services.xserver.xkb.options = "grp:ctrl_space_toggle";

  # Enable sound via PipeWire.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      fira
      liberation_ttf
      nerd-fonts.fira-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      antialias = true;
      defaultFonts = {
        sansSerif = [
          "Fira Sans"
          "Noto Sans"
        ];
        serif = [ "Noto Serif" ];
        monospace = [
          "FiraMono Nerd Font"
          "Noto Sans Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };
  };

  # Keep generic Wayland app support enabled across desktop sessions.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # No xdg.portal block. The GNOME and Hyprland modules turn portals on and
  # add the gnome, gtk and hyprland portals themselves.
}
