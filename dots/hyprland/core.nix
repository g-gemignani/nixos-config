{
  config,
  lib,
  pkgs,
  theme,
  ...
}:

let
  terminal = lib.getExe config.programs.alacritty.package;
  hyprbars = pkgs.hyprlandPlugins.hyprbars.overrideAttrs (_: {
    version = "unstable-2026-04-18";
    src =
      pkgs.fetchFromGitHub {
        owner = "hyprwm";
        repo = "hyprland-plugins";
        rev = "6059aca0cc623d8d896b02842606036c0954ba88";
        sha256 = "1j0ack8s7rfvalhpdp1qm0jfg7cf3axyxyqhgrby1s5w8i4isz9m";
      }
      + "/hyprbars";
  });
  brightnessctl = lib.getExe pkgs.brightnessctl;
  flameshot = lib.getExe pkgs.flameshot;
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  thunarExe = lib.getExe pkgs.thunar;
  pactl = lib.getExe' pkgs.pulseaudio "pactl";
  xdgOpen = lib.getExe' pkgs.xdg-utils "xdg-open";
  openFileManager = pkgs.writeShellScript "open-file-manager" ''
    set -eu

    if command -v ${thunarExe} >/dev/null 2>&1; then
      ${thunarExe} "$HOME" >/dev/null 2>&1 &
      exit 0
    fi

    exec ${xdgOpen} "$HOME"
  '';
  saveFullscreenScreenshot = pkgs.writeShellScript "save-fullscreen-screenshot" ''
    set -eu

    dir="$HOME/Pictures/Screenshots"
    file="$dir/$(date +%Y-%m-%d-%H%M%S).png"

    mkdir -p "$dir"
    ${flameshot} full -p "$file"
  '';
  swayosd-client = lib.getExe' config.services.swayosd.package "swayosd-client";
  dimBrightness = "50%";
  dimTimeoutSeconds = 60;
  lockTimeoutSeconds = 300;
  screenOffTimeoutSeconds = 360;
  sleepTimeoutSeconds = 1800;
in
{
  fonts.fontconfig.enable = true;

  systemd.user.services.hyprland-wallpaper = {
    Unit = {
      Description = "Hyprland wallpaper";
    };

    Service = {
      ExecStart = "${lib.getExe pkgs.swaybg} -i ${theme.wallpaper} -m fill";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  home.activation.restartHyprlandWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if systemctl --user show-environment | grep -q '^WAYLAND_DISPLAY='; then
      systemctl --user restart hyprland-wallpaper.service || systemctl --user start hyprland-wallpaper.service
    fi
  '';

  home.packages =
    theme.packages
    ++ (with pkgs; [
      grim
      pavucontrol
      swaybg
      thunar
    ]);

  xdg.configFile."flameshot/flameshot.ini".text = ''
    [General]
    disabledGrimWarning=true
    useGrimAdapter=true
  '';

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    XCURSOR_SIZE = toString theme.pointerCursor.size;
  };

  gtk = theme.gtk;
  qt = theme.qt;
  home.pointerCursor = theme.pointerCursor;

  services.mako = {
    enable = true;
    settings = theme.makoSettings;
  };

  services.swayosd = {
    enable = true;
    stylePath = pkgs.writeText "swayosd-style.css" theme.swayosdStyle;
  };

  programs.hyprlock = {
    enable = true;
    settings = theme.hyprlockSettings;
  };

  services.hypridle = {
    enable = true;
    settings =
      let
        isLocked = "pgrep -x hyprlock > /dev/null";
        hyprlock = lib.getExe config.programs.hyprlock.package;
      in
      {
        general = {
          lock_cmd = "if ! ${isLocked}; then ${hyprlock}; fi";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on; ${brightnessctl} -r";
          ignore_dbus_inhibit = false;
        };
        listener = [
          {
            timeout = dimTimeoutSeconds;
            on-timeout = "${brightnessctl} -s s ${dimBrightness}";
            on-resume = "${brightnessctl} -r";
          }
          {
            timeout = lockTimeoutSeconds;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = screenOffTimeoutSeconds;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on; ${brightnessctl} -r";
          }
          {
            timeout = sleepTimeoutSeconds;
            on-timeout = "systemctl suspend";
          }
        ];
      };
  };

  programs.wofi = {
    enable = true;
    settings = theme.wofiSettings;
    style = theme.wofiStyle;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = theme.waybarSettings;
    style = theme.waybarStyle;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [ hyprbars ];
    systemd.enable = false;
    xwayland.enable = true;
    settings = theme.hyprlandSettings // {
      "$mod" = "SUPER";

      monitor = [
        "HDMI-A-2,preferred,0x0,1"
        "eDP-1,preferred,1920x0,1"
        ",preferred,auto,1"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user restart hyprland-wallpaper.service || systemctl --user start hyprland-wallpaper.service"
      ];

      env = [
        "XCURSOR_SIZE,${toString theme.pointerCursor.size}"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "NIXOS_OZONE_WL,1"
      ];

      xwayland = {
        force_zero_scaling = true;
      };

      input = {
        kb_layout = "de,us";
        kb_options = "grp:ctrl_space_toggle";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        on_focus_under_fullscreen = 1;
      };

      binds = {
        movefocus_cycles_fullscreen = true;
      };

      bind = [
        "$mod,Return,exec,${terminal}"
        "$mod,B,exec,google-chrome-stable"
        "$mod,N,exec,${openFileManager}"
        "$mod,SPACE,exec,wofi --show drun"
        "$mod,TAB,cyclenext,visible"
        "$mod,BackSpace,exec,${lib.getExe config.programs.hyprlock.package}"
        "$mod,L,exec,loginctl lock-session && systemctl suspend"
        "$mod,Q,killactive"
        "$mod,F,fullscreen,1"
        "$mod,V,togglefloating"
        "$mod,P,pseudo"
        "$mod,left,movefocus,l"
        "$mod,right,movefocus,r"
        "$mod,up,movefocus,u"
        "$mod,down,movefocus,d"
        "$mod SHIFT,left,movewindow,l"
        "$mod SHIFT,right,movewindow,r"
        "$mod SHIFT,up,movewindow,u"
        "$mod SHIFT,down,movewindow,d"
        "$mod,1,workspace,1"
        "$mod,2,workspace,2"
        "$mod,3,workspace,3"
        "$mod,4,workspace,4"
        "$mod,5,workspace,5"
        "$mod SHIFT,1,movetoworkspace,1"
        "$mod SHIFT,2,movetoworkspace,2"
        "$mod SHIFT,3,movetoworkspace,3"
        "$mod SHIFT,4,movetoworkspace,4"
        "$mod SHIFT,5,movetoworkspace,5"
        ",Print,exec,${saveFullscreenScreenshot}"
        "SHIFT,Print,exec,${flameshot} gui"
      ];

      bindel = [
        ",XF86MonBrightnessUp,exec,${brightnessctl} s +10%; ${swayosd-client} --brightness +0"
        ",XF86MonBrightnessDown,exec,${brightnessctl} s 10%-; ${swayosd-client} --brightness +0"
        ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%; ${swayosd-client} --output-volume +0"
        ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%; ${swayosd-client} --output-volume +0"
      ];

      bindl = [
        ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle; ${swayosd-client} --output-volume +0"
        ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle; ${swayosd-client} --input-volume +0"
      ];

      bindm = [
        "$mod,mouse:272,movewindow"
        "$mod,mouse:273,resizewindow"
      ];
    };
  };
}
