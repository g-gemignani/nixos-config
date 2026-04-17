{ lib, pkgs }:

let
  rgb = color: "rgb(${lib.removePrefix "#" color})";
  rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
  colors = {
    background = "#0f1118";
    surface = "#171b24";
    surfaceAlt = "#202534";
    surfaceBright = "#2a3144";
    border = "#343c52";
    text = "#e8ecf3";
    muted = "#a7b0c0";
    primary = "#8fb4ff";
  };
  sansFont = "Fira Sans";
  monoFont = "FiraMono Nerd Font";
  surfaceOverlay = "rgba(23, 27, 36, 0.88)";
  wallpaperImage =
    pkgs.runCommandLocal "hyprland-wallpaper.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 2560x1440 gradient:'#0f1118-#202534' \
          -fill 'rgba(143,180,255,0.22)' -draw 'circle 380,260 380,-120' \
          -fill 'rgba(143,180,255,0.12)' -draw 'circle 2180,1080 2180,760' \
          -fill 'rgba(232,236,243,0.05)' -draw 'rectangle 0,0 2559,1439' \
          "$out"
      '';
in
{
  name = "midnight";

  packages = with pkgs; [
    bibata-cursors
    fira
    materia-theme
    nerd-fonts.fira-mono
    papirus-icon-theme
  ];

  wallpaper = wallpaperImage;

  gtk = {
    enable = true;
    gtk4.theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };
    font = {
      name = sansFont;
      size = 11;
    };
    theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  makoSettings = {
    anchor = "top-center";
    background-color = "${colors.surface}dd";
    border-color = "${colors.primary}ff";
    border-radius = 10;
    border-size = 2;
    default-timeout = 8000;
    font = "${sansFont} 11";
    height = 140;
    icons = true;
    layer = "overlay";
    padding = "12,18";
    text-color = colors.text;
    width = 420;
  };

  swayosdStyle = ''
    window {
      padding: 0 1em;
      border-radius: 999px;
      background-color: ${colors.surface};
      border: 1px solid ${colors.border};
      opacity: 0.92;
    }

    #container {
      margin: 1em;
    }

    image {
      color: ${colors.primary};
      opacity: 0.95;
    }

    image:disabled {
      color: ${colors.muted};
      opacity: 0.75;
    }

    label {
      color: ${colors.text};
    }

    progress {
      min-height: inherit;
      border-radius: inherit;
      border: none;
      background-color: ${colors.primary};
      opacity: 0.95;
    }

    progressbar {
      min-height: 0.55em;
      border-radius: inherit;
      background-color: transparent;
      border: none;
      opacity: 0.9;
    }

    progressbar:disabled {
      opacity: 0.55;
    }

    trough {
      min-height: inherit;
      border-radius: inherit;
      border: none;
      background-color: ${colors.surfaceBright};
      opacity: 1;
    }
  '';

  hyprlockSettings = {
    general = {
      disable_loading_bar = true;
      hide_cursor = true;
    };
    animations = {
      enabled = true;
      bezier = [ "easeOut,0.22,1,0.36,1" ];
      animation = [
        "fade,1,4,easeOut"
        "inputField,1,4,easeOut"
      ];
    };
    background = {
      monitor = "";
      path = "screenshot";
      blur_passes = 3;
      blur_size = 8;
      brightness = 0.72;
    };
    input-field = [
      {
        monitor = "";
        size = "320, 56";
        position = "0, -40";
        halign = "center";
        valign = "center";
        dots_center = true;
        dots_size = 0.2;
        dots_spacing = 0.22;
        outer_color = rgb colors.primary;
        inner_color = rgb colors.surface;
        font_color = rgb colors.text;
        check_color = rgb colors.primary;
        fail_color = "rgb(ff6b81)";
        outline_thickness = 2;
        fade_on_empty = false;
        placeholder_text = "Password";
        fail_text = "Authentication failed";
        capslock_color = rgb colors.primary;
      }
    ];
    label = [
      {
        monitor = "";
        text = "$TIME";
        color = rgb colors.text;
        font_family = sansFont;
        font_size = 72;
        position = "0, 120";
        halign = "center";
        valign = "center";
      }
      {
        monitor = "";
        text = "cmd[update:60000] date '+%A, %d %B'";
        color = rgb colors.muted;
        font_family = sansFont;
        font_size = 20;
        position = "0, 45";
        halign = "center";
        valign = "center";
      }
    ];
  };

  wofiSettings = {
    allow_images = true;
    columns = 2;
    image_size = 40;
    insensitive = true;
    matching = "multi-contains";
    prompt = "Search";
  };

  wofiStyle = ''
    * {
      font-family: ${sansFont}, ${monoFont};
      font-size: 14px;
    }

    window {
      margin: 0;
      padding: 18px;
      border: 2px solid ${colors.primary};
      border-radius: 18px;
      background-color: ${colors.surface};
      color: ${colors.text};
    }

    #outer-box {
      margin: 0;
      padding: 0;
    }

    #input {
      margin: 0 0 16px 0;
      padding: 14px 16px;
      border: none;
      border-radius: 12px;
      background-color: ${colors.surfaceAlt};
      color: ${colors.text};
    }

    #entry {
      margin: 6px 0;
      padding: 12px 14px;
      border-radius: 12px;
    }

    #entry:selected {
      background-color: ${colors.primary};
      color: ${colors.background};
    }

    #text {
      color: inherit;
    }

    #img {
      margin-right: 12px;
    }
  '';

  waybarSettings = {
    mainBar = {
      exclusive = false;
      height = 40;
      layer = "top";
      margin = "15 15 0 15";
      position = "top";
      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "tray"
      ];

      "hyprland/workspaces" = {
        active-only = false;
        all-outputs = false;
        format = "{name}";
        on-click = "activate";
        persistent-workspaces = {
          "*" = 5;
        };
      };

      "hyprland/window" = {
        max-length = 60;
        separate-outputs = true;
      };

      clock = {
        format = "{:%H:%M  %d/%m}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      cpu = {
        format = "CPU {usage}%";
        interval = 5;
      };

      memory = {
        format = "RAM {}%";
        interval = 5;
      };

      network = {
        format-wifi = "WiFi {essid}";
        format-ethernet = "LAN";
        format-disconnected = "Offline";
        tooltip-format = "{ifname} {ipaddr}/{cidr}";
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "MUTED";
        on-click = "pavucontrol";
      };

      tray = {
        spacing = 10;
      };
    };
  };

  waybarStyle = ''
    * {
      border: none;
      border-radius: 0;
      font-family: ${sansFont}, ${monoFont};
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: transparent;
      color: ${colors.text};
    }

    .modules-left,
    .modules-center,
    .modules-right {
      background: ${surfaceOverlay};
      border: 1px solid ${colors.border};
      border-radius: 14px;
      padding: 0 8px;
    }

    #workspaces button,
    #clock,
    #pulseaudio,
    #network,
    #cpu,
    #memory,
    #tray,
    #window {
      color: ${colors.text};
      margin: 6px 4px;
      padding: 6px 12px;
      border-radius: 10px;
    }

    #workspaces button {
      background: transparent;
      color: ${colors.muted};
    }

    #workspaces button.active {
      background: ${colors.primary};
      color: ${colors.background};
    }

    #workspaces button:hover,
    #pulseaudio:hover,
    #network:hover,
    #cpu:hover,
    #memory:hover,
    #clock:hover {
      background: ${colors.surfaceBright};
      color: ${colors.text};
    }

    #window {
      color: ${colors.muted};
    }
  '';

  hyprlandSettings = {
    layerrule = [
      "blur on, match:namespace waybar"
      "ignore_alpha 0, match:namespace waybar"
      "blur on, match:namespace notifications"
      "ignore_alpha 0, match:namespace notifications"
      "blur on, match:namespace launcher"
      "ignore_alpha 0, match:namespace launcher"
    ];

    plugin.hyprbars = {
      bar_color = rgba colors.surface "dd";
      "col.text" = rgb colors.primary;
      bar_height = 25;
      bar_text_font = sansFont;
      bar_text_size = 11;
      bar_part_of_window = false;
      bar_precedence_over_border = false;
      hyprbars-button = [
        "rgb(ff6b81),12,,hyprctl dispatch killactive"
        "rgb(f9e2af),12,,hyprctl dispatch fullscreen 1"
        "rgb(a6e3a1),12,,hyprctl dispatch togglegroup"
      ];
    };

    general = {
      border_size = 2;
      gaps_in = 10;
      gaps_out = 16;
      "col.active_border" = rgb colors.primary;
      "col.inactive_border" = rgb colors.border;
      layout = "dwindle";
    };

    decoration = {
      active_opacity = 1.0;
      inactive_opacity = 0.92;
      rounding = 14;
      shadow.enabled = false;
    };

    animations = {
      enabled = true;
      bezier = [ "easeOut,0.22,1,0.36,1" ];
      animation = [
        "windows,1,5,easeOut"
        "windowsOut,1,5,easeOut,popin 80%"
        "border,1,8,easeOut"
        "fade,1,5,easeOut"
        "workspaces,1,5,easeOut"
      ];
    };

    windowrule = [
      "hyprbars:no_bar on, match:float 1"
      "hyprbars:bar_color ${rgba colors.surface "dd"}, match:focus 0"
      "hyprbars:title_color ${rgb colors.primary}, match:focus 0"
      "hyprbars:bar_color ${rgba colors.primary "ee"}, match:focus 1"
      "hyprbars:title_color ${rgb colors.background}, match:focus 1"
      "float on, match:class ^(pavucontrol)$"
      "float on, match:class ^(org\\.gnome\\.Calculator)$"
      "size 900 600, match:class ^(pavucontrol)$"
    ];
  };
}
