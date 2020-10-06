{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.09;
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware;

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.delilah = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9550
        ./configuration.nix
        ({
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
