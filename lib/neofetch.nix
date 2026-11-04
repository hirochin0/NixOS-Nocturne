{ lib, stdenvNoCC, makeWrapper, bash, coreutils, gnugrep, gnused, gawk
, procps, pciutils, util-linux, ncurses, src }:
stdenvNoCC.mkDerivation {
  pname = "neofetch";
  version = "7.1.0";
  inherit src;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 neofetch "$out/bin/neofetch"
    install -Dm644 neofetch.1 "$out/share/man/man1/neofetch.1"
    patchShebangs "$out/bin/neofetch"
    wrapProgram "$out/bin/neofetch" --prefix PATH : ${lib.makeBinPath [
      bash coreutils gnugrep gnused gawk procps pciutils util-linux ncurses
    ]}
    runHook postInstall
  '';
  meta = {
    description = "Original Neofetch, pinned to its final release";
    homepage = "https://github.com/dylanaraps/neofetch";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "neofetch";
  };
}
