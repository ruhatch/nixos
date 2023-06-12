{
  description = "A simple modpack.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.minecraft = {
    url = "github:Ninlives/minecraft.nix";
    inputs.metadata.follows = "minecraft-metadata";
  };
  inputs.minecraft-metadata.url = "github:Ninlives/minecraft.json";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, minecraft, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) fetchurl stdenv;
    in {
      packages.minecraft-realistic =
        (minecraft.legacyPackages.${system}.v1_19_4.fabric.client.withConfig [{
          mods = [
            (fetchurl {
              # file name must have a ".jar" suffix to be loaded by fabric
              name = "fabric-api.jar";
              url =
                "https://cdn.modrinth.com/data/P7dR8mSH/versions/5U5Y73uW/fabric-api-0.83.0%2B1.19.4.jar";
              sha256 =
                "sha256:0cgag7fvn38yl7yivppgnax73f4ancck1424pr7v88bly8g4anrl";
            })
            (fetchurl {
              name= "sodium.jar";
              url =
                "https://cdn.modrinth.com/data/AANobbMI/versions/b4hTi3mo/sodium-fabric-mc1.19.4-0.4.10%2Bbuild.24.jar";
              sha256 =
                "sha256:06nsbnppdv1h3d2r1940y9zww810qs11zf0khsf02rarbbj83g6i";
            })
            (fetchurl {
              url =
                "https://cdn.modrinth.com/data/YL57xq9U/versions/4dFzaTaP/iris-mc1.19.4-1.6.4.jar";
              sha256 =
                "sha256:0535k5bxxghhd482gpjfwish6fhfa7l4ddnik757r3079rs90sf8";
            })
          ];
          resourcePacks = [
            (fetchurl {
              name = "optimum-realism.zip";
              url =
                "https://www.curseforge.com/api/v1/mods/513233/files/4578018/download";
              sha256 =
                "sha256:1ndd3c7xqw841vhscn1xkxj5igshhgy3dlhsfs725759nqxi32iq";
            })
            (stdenv.mkDerivation {
              name = "seus.zip";
              outputHash = "sha256:76a1ff6c0d7827ecd0857e5a9b5298337f232662767abf0f011154c85b6da8ef";
              buildInputs = [ pkgs.curl pkgs.cacert ];
              unpackPhase = "true";
              buildPhase = ''
                curl --cookie 'PHPSESSID=50b279307edf670649b4e843894261ff' 'https://sonicether.com/shaders/download/renewed-v1-0-1/agree.php'
                curl --cookie 'PHPSESSID=50b279307edf670649b4e843894261ff' 'https://sonicether.com/shaders/download/renewed-v1-0-1/download.php' --output 'seus.zip'
              '';
              installPhase = ''
                cp seus.zip $out
              '';
            })
          ];
        }]);
    });
}
