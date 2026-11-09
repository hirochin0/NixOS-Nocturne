{ pkgs }:
let
  python = pkgs.python3.withPackages (p: [ p.dbus-next ]);
in pkgs.writeShellScriptBin "nocturne-battery" ''
  exec ${python}/bin/python3 ${../home/scripts/battery.py} "$@"
''
