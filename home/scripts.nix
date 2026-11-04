{ lib, pkgs, desktop, ... }: {
  home.packages = lib.attrValues (import ../lib/tools.nix { inherit pkgs desktop; });
}
