{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
  inputs.nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  inputs.unfree-nixpkgs.url = path:unfree-nixpkgs;
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware;
  inputs.onlyoffice.url = github:GTrunSec/onlyoffice-desktopeditors-flake;

  outputs = { self, nixpkgs, unfree-nixpkgs, nixpkgs-unstable, nixos-hardware, onlyoffice }: {
    nixosConfigurations.delilah = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9550
        ./configuration.nix
        ({
          environment.systemPackages = [
            onlyoffice.defaultPackage."${system}"
            ((import nixpkgs { inherit system; }).callPackage ./starport.nix { inherit (import nixpkgs-unstable { inherit system; }) buildGoModule; })
          ];

          system.configurationRevision =
            if self ? rev
            then self.rev
            else throw "Refusing to build from a dirty Git tree!";

          nix.registry.nixpkgs.flake = nixpkgs;
          nix.registry.unfree-nixpkgs.flake = unfree-nixpkgs;
        })
      ];
    };
  };
}
