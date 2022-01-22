{
  description = "Unfree nixpkgs";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;

  outputs = {self, nixpkgs}: {
    packages."x86_64-linux" = 
      with import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      { inherit zoom-us; };
  };
}
