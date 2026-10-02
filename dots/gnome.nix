# GNOME Shell visuals.
#
# The GTK theme, the icons, the cursor and the fonts already come from
# dots/hyprland/themes. Home Manager writes those to the same dconf keys that
# GNOME reads, so they carry over to this session at no extra cost. What they
# do not touch is GNOME Shell itself: the top bar, the overview and the dash
# are drawn by the shell, not by GTK. This file covers only that gap, plus
# wallpaper rotation.
{ lib, pkgs, ... }:

let
  extensions = with pkgs.gnomeExtensions; [
    blur-my-shell
    dash-to-dock
    just-perfection
    user-themes
  ];
in
{
  home.packages = extensions ++ [
    pkgs.gnome-tweaks
    pkgs.variety
  ];

  # Variety has no module and writes its own autostart entry on first run.
  # Linking the desktop file keeps that state in the repo instead of in
  # ~/.config, so a fresh machine rotates wallpapers without a manual step.
  xdg.configFile."autostart/variety.desktop".source =
    "${pkgs.variety}/share/applications/variety.desktop";

  # GNOME asks before an app takes a screenshot through the portal. It shows
  # that dialog only for the focused app, and flameshot never has focus, so
  # every capture fails. A stored "yes" skips the dialog. The portal takes
  # the app ID from the systemd scope name: the autostart daemon runs in
  # app-gnome-Flameshot-<pid>.scope, and the Shift+Print command in
  # app-gnome-env-<pid>.scope. The call fails outside a session, which is
  # harmless.
  home.activation.allowPortalScreenshot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for app in Flameshot env; do
      ${pkgs.glib.bin}/bin/gdbus call --session \
        -d org.freedesktop.impl.portal.PermissionStore \
        -o /org/freedesktop/impl/portal/PermissionStore \
        -m org.freedesktop.impl.portal.PermissionStore.SetPermission \
        screenshot true screenshot "$app" "['yes']" >/dev/null 2>&1 || true
    done
  '';

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = map (e: e.extensionUuid) extensions;
    };

    # Files, Settings and the other libadwaita apps ignore the GTK theme name
    # and read this key alone. Without it they stay light next to a
    # Materia-dark window, which is most of what makes the session look
    # unfinished.
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    # Blur the top bar and the overview. Static blur samples the wallpaper
    # once instead of every frame, which matters because Variety changes the
    # wallpaper on a timer.
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      static-blur = true;
      brightness = 0.75;
      sigma = 30;
    };
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
      style-components = 3;
    };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      static-blur = true;
      brightness = 0.6;
      sigma = 30;
    };

    # Shift+Print opens flameshot. GNOME binds Shift+Print to its own
    # full-screen shot by default, so that action moves to Alt+Print.
    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Alt>Print" ];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Flameshot GUI";
      binding = "<Shift>Print";
      command = "env QT_QPA_PLATFORM=xcb flameshot gui";
    };

    # A dock on the left edge, sized to its icons rather than the full screen,
    # and hidden while a window needs the space.
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      dock-fixed = false;
      extend-height = false;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      dash-max-icon-size = 40;
      click-action = "minimize-or-previous";
      running-indicator-style = "DOTS";
      # Blur My Shell draws the background, so the dock must not paint one.
      transparency-mode = "FIXED";
      background-opacity = 0.0;
      apply-custom-theme = false;
    };

    # Rounder corners and a smaller bar, so the shell stops looking like a
    # default install. Everything else stays at the GNOME default.
    "org/gnome/shell/extensions/just-perfection" = {
      panel-size = 32;
      panel-corner-size = 12;
      workspace-background-corner-size = 12;
      animation = 3;
      startup-status = 0;
      window-preview-caption = false;
      workspace-peek = true;
    };
  };
}
