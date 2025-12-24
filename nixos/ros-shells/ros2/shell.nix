{ pkgs ? import <nixpkgs> {}, ... }:

let
  ros-overlay = builtins.fetchTarball {
    url = "https://github.com/ros-infrastructure/ros-overlay/archive/refs/heads/master.tar.gz";
  };

  pkgsWithRos = import (pkgs.lib.cleanSource ros-overlay) {
    overlays = [ (final: prev: { inherit (pkgs) lib; }) ];
    inherit pkgs;
  };

in pkgs.mkShell {
  buildInputs = with pkgs; [
    git
    cmake
    python3
    pkg-config
    colcon
    colcon-common-extensions
  ] ++ (with pkgsWithRos; [ ros-humble-desktop ]) ;

  shellHook = ''
    # Source ROS2 (humble) setup if present
    if [ -f /opt/ros/humble/setup.bash ]; then
      source /opt/ros/humble/setup.bash
    fi
    export ROS_WORKSPACE="$HOME/Coding/ros2/colcon_ws"
  '';
}
