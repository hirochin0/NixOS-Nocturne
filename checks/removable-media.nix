{ pkgs }:
let tools = import ../lib/removable-tools.nix { inherit pkgs; };
in pkgs.runCommand "nocturne-removable-media-check" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  python ${./removable_media_test.py} ${../home/scripts/removable_media.py}
  ${tools}/bin/nocturne-usb --help > "$out"
''
