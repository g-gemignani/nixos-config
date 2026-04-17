{ ... }:
{
  xdg.mimeApps = {
    associations.added = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      keyboard.bindings = [
        {
          key = "N";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];
      font = {
        size = 10;
        normal = {
          family = "FiraMono Nerd Font";
          style = "Medium";
        };
      };
      window = {
        padding = {
          x = 24;
          y = 26;
        };
      };
    };
  };
}
