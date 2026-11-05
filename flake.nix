{
  description = "NOCTURNE — modular NixOS / Hyprland rice";
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 最新安定版を明示。nixpkgsは上流のlockに従い、Mesa/XDPHも同じ集合を使う。
    hyprland.url = "github:hyprwm/Hyprland/v0.57.1";
    swww.url = "github:LGFae/swww/v0.11.2";
    neofetch-src = {
      url = "github:dylanaraps/neofetch/7.1.0";
      flake = false;
    };
  };
  outputs = { nixpkgs, home-manager, hyprland, swww, neofetch-src, ... }:
    let
      user = import ./user.nix;
      theme = import ./theme.nix;
      pkgs = nixpkgs.legacyPackages.${user.system};
      desktop = import ./lib/desktop-packages.nix {
        inherit hyprland swww neofetch-src;
        system = user.system;
      };
    in {
      checks.${user.system} = {
        hyprland-config = import ./lib/hyprland-config.nix { inherit pkgs desktop user theme; };
        system-contract = import ./checks/system-contract.nix {
          inherit nixpkgs home-manager user theme desktop;
        };
        dconf-activation = import ./checks/dconf-activation.nix {
          inherit pkgs home-manager desktop user theme;
        };
        wallpaper-tools = import ./checks/wallpaper-tools.nix { inherit pkgs desktop theme; };
        quickshell = import ./checks/quickshell.nix { inherit pkgs desktop theme user; };
        application-cli = pkgs.runCommand "nocturne-application-cli" {
          nativeBuildInputs = [ desktop.codex desktop.neofetch ];
        } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          codex --version > "$out"
          # Original Neofetch deliberately exits 1 for --version.
          status=0
          version=$(neofetch --version) || status=$?
          test "$status" -eq 1
          test "$version" = "Neofetch 7.1.0"
          printf '%s\n' "$version" >> "$out"
        '';
      };
      nixosConfigurations.${user.hostName} = nixpkgs.lib.nixosSystem {
        system = user.system;
        specialArgs = { inherit user theme desktop; };
        modules = [
          ./hosts/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit user theme desktop; };
              users.${user.name} = import ./home;
            };
          }
        ];
      };
    };
}
