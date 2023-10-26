{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "dellfan";
  src = fetchFromGitHub {
    owner = "clopez";
    repo = "dellfan";
    rev = "43439951144b0feb6019e1901e53d60a619a7c6c";
    hash = "sha256-L3HjXnkBKxdwqJarsOIFNyZYr+u9bjMiezDS12Dh2sg=";
  };

  postUnpack = ''
    sed -i -e '173d' source/dellfan.c
    sed -i 's/0x0001/0x3000/g' source/dellfan.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp dellfan $out/bin
  '';

  meta = with lib; {
    description = "Take control of fans on Dell";
    homepage = "https://github.com/clopez/dellfan";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
