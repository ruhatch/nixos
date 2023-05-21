{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
  inputs.nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  inputs.unfree-nixpkgs.url = path:unfree-nixpkgs;
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware;
  inputs.minecraft-nix.url = github:Ninlives/minecraft.nix;

  outputs = { self, nixpkgs, unfree-nixpkgs, nixpkgs-unstable, nixos-hardware, minecraft-nix }: {
    nixosConfigurations.delilah = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9550
        ./configuration.nix
        ({
          system.configurationRevision =
            if self ? rev
            then self.rev
            else throw "Refusing to build from a dirty Git tree!";

          nix.  nixPath = [
	    "nixpkgs=${nixpkgs}"
	    "/nix/var/nix/profiles/per-user/root/channels"
	  ];

          nix.registry.nixpkgs.flake = nixpkgs;
          nix.registry.unfree-nixpkgs.flake = unfree-nixpkgs;
          nix.registry.minecraft.flake = minecraft-nix;
        })
      ];
    };
  };
}
