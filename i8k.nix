{ stdenv, lib, fetchFromGitHub, pkgs, tcl, tcllib }:

stdenv.mkDerivation rec {
  name = "i8kutils-${version}";
  version = "1.6";

  src = fetchFromGitHub {
    owner = "Wer-Wolf";
    repo = "i8kutils";
    rev = "58ced78ab04d7d46ff2447c19f1cfd935ad2fa75";
    hash = "sha256-Tx3sOIbGi+wLsAq7eTM+UXgHKhbRzYM7xrin+g7ivrc=";
  };

  mesonFlags = [
    "-Dmoduledir=${placeholder "out"}/lib"
  ];

  postUnpack = ''
    sed -i '/etc/d' source/meson.build
  '';

  nativeBuildInputs = with pkgs; [ meson ninja ];
  buildInputs = with pkgs; [ pkg-config cmake systemd makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/i8kmon" \
      --set PATH ${lib.makeBinPath [ tcl ]} \
      --set TCL8_6_TM_PATH "$out/lib" \
      --set TCLLIBPATH "${tcl}/lib ${tcllib}/lib"
    wrapProgram "$out/bin/i8kctl" --set TCL8_6_TM_PATH "$out/lib"
  '';

  meta = with lib; {
    description = "A kernel module to control fans on Dell";
    homepage = "https://github.com/Wer-Wolf/i8kutils";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
