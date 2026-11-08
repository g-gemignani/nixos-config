{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    # shortcut: VS Code 1.144 moved its bundled rg, and the nixpkgs postPatch
    # still removes the old path. Drop this once nixpkgs fixes the path.
    package = pkgs.vscode.overrideAttrs (old: {
      postPatch =
        builtins.replaceStrings
          [ "resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
          [ "resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg" ]
          old.postPatch;
    });

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
