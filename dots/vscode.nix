{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-python.python
      ];
      userSettings = {
        "nix.serverPath" = "nixd";
        "editor.formatOnSave" = true;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "github.copilot.nextEditSuggestions.enabled" = true;
      };
    };
  };
}
