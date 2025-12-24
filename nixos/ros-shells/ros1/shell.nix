{ pkgs ? import <nixpkgs> {}, ... }:

let
  ros-overlay = builtins.fetchTarball {
    # use a stable ros-overlay release; you can pin this in your flake later
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
  ] ++ (with pkgsWithRos; [ ros-noetic-desktop ]) ;

  shellHook = ''
    # Source ROS1 (noetic) setup if present
    if [ -f /opt/ros/noetic/setup.bash ]; then
      source /opt/ros/noetic/setup.bash
    fi
    export ROS_WORKSPACE="$HOME/Coding/ros1/catkin_ws"
  '';
}
