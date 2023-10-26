{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "dell-bios-fan-control";
  src = fetchFromGitHub {
    owner = "TomFreudenberg";
    repo = "dell-bios-fan-control";
    rev = "27006106595bccd6c309da4d1499f93d38903f9a";
    hash = "sha256-3ihzvwL86c9VJDfGpbWpkOwZ7qU0E5U2UuOeCwPMR1s=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp dell-bios-fan-control $out/bin
  '';

  meta = with lib; {
    description = "Take control of fans on Dell";
    homepage = "https://github.com/TomFreudenberg/dell-bios-fan-control";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
