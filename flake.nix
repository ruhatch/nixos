{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.09;
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware;
  inputs.onlyoffice.url = github:GTrunSec/onlyoffice-desktopeditors-flake;

  outputs = { self, nixpkgs, nixos-hardware, onlyoffice }: {
    nixosConfigurations.delilah = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9550
        ./configuration.nix
        ({
          environment.systemPackages = [ onlyoffice.defaultPackage."${system}" ];

          system.configurationRevision =
            if self ? rev
            then self.rev
            else throw "Refusing to build from a dirty Git tree!";

          nix.registry.nixpkgs.flake = nixpkgs;
        })
      ];
    };
  };
}
