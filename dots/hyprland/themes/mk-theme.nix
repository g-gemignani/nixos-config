{ lib, pkgs }:

{
  name,
  colors,
  sansFont,
  monoFont,
  surfaceOverlay,
  wallpaper,
  extraPackages ? [ ],
  gtkThemeName ? "Materia-dark",
  gtkThemePackage ? pkgs.materia-theme,
  iconThemeName ? "Papirus-Dark",
  iconThemePackage ? pkgs.papirus-icon-theme,
  cursorName ? "Bibata-Modern-Ice",
  cursorPackage ? pkgs.bibata-cursors,
  cursorSize ? 24,
  terminalPalette,
  terminalOpacity ? 0.96,
}:

let
  rgb = color: "rgb(${lib.removePrefix "#" color})";
  rgba = color: alpha: "rgba(${lib.removePrefix "#" color}${alpha})";
in
{
  inherit name wallpaper;

  packages = extraPackages;

  alacrittySettings = {
    font = {
      size = 10;
      normal = {
        family = monoFont;
        style = "Medium";
      };
    };
    window.opacity = terminalOpacity;
    colors = {
      primary = {
        background = colors.background;
        foreground = colors.text;
        dim_foreground = colors.muted;
        bright_foreground = colors.text;
      };
      cursor = {
        text = colors.background;
        cursor = colors.primary;
      };
      selection = {
        text = colors.background;
        background = colors.primary;
      };
      normal = terminalPalette.normal;
      bright = terminalPalette.bright;
    };
  };

  gtk = {
    enable = true;
    gtk4.theme = {
      name = gtkThemeName;
      package = gtkThemePackage;
    };
    font = {
      name = sansFont;
      size = 11;
    };
    theme = {
      name = gtkThemeName;
      package = gtkThemePackage;
    };
    iconTheme = {
      name = iconThemeName;
      package = iconThemePackage;
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
    package = cursorPackage;
    name = cursorName;
    size = cursorSize;
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
      exclusive = true;
      height = 43;
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
        "custom/power"
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

      "custom/power" = {
        format = "PWR";
        on-click = "toggle-power-menu";
        tooltip = false;
      };
    };
  };

  wlogoutStyle = ''
    window {
      background: rgba(0, 0, 0, 0.45);
    }

    button {
      background: ${surfaceOverlay};
      border: 1px solid ${colors.border};
      border-radius: 18px;
      box-shadow: none;
      color: ${colors.text};
      font-family: ${sansFont}, ${monoFont};
      font-size: 18px;
      margin: 14px;
      min-height: 96px;
      min-width: 180px;
      padding: 18px 24px;
    }

    button:focus,
    button:hover {
      background: ${colors.surfaceBright};
      border-color: ${colors.primary};
      color: ${colors.text};
    }

    #shutdown,
    #reboot,
    #logout,
    #sleep,
    #lock {
      background-image: none;
    }
  '';

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
    #custom-power,
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
    #custom-power:hover,
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
