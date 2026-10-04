# Zed as the text editor, in place of GNOME Text Editor. Its Markdown
# preview (Ctrl+K V) follows the editor theme and colors code blocks.
{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.zed-editor ];

  # Most text types fall back to text/plain. The rest are listed because
  # another app claims them by name, and a named claim beats the fallback.
  xdg.mimeApps.defaultApplications = lib.genAttrs [
    "text/plain"
    "text/markdown"
    "text/x-python"
    "text/x-shellscript"
    "text/x-csrc"
    "text/x-c++src"
    "application/json"
    "application/x-yaml"
    "application/toml"
    "application/xml"
  ] (_: "dev.zed.Zed.desktop");
}
