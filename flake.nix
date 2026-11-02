{
  description = "NOCTURNE — modular NixOS / Hyprland rice";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }:
    let user = import ./user.nix; theme = import ./theme.nix;
    in {
      nixosConfigurations.${user.hostName} = nixpkgs.lib.nixosSystem {
        system = user.system;
        specialArgs = { inherit user theme; };
        modules = [
          ./hosts/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit user theme; };
              users.${user.name} = import ./home;
            };
          }
        ];
      };
    };
}
