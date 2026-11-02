{ ... }: {
  imports = [
    ./base/configuration.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/japanese.nix
  ];
}
