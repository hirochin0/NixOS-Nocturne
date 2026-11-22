{ pkgs, desktop }:
let
  python = pkgs.python3.withPackages (p: [ p.pywayland p.pillow ]);
  source = desktop.quickshell.src;
in pkgs.runCommand "nocturne-preview" {
  nativeBuildInputs = [ python pkgs.makeWrapper ];
} ''
  mkdir -p "$out/bin" "$out/lib/preview_protocols"
  python ${../home/scripts/generate_preview_protocols.py} "$out/lib/preview_protocols" \
    ${source}/src/wayland/toplevel/wlr-foreign-toplevel-management-unstable-v1.xml \
    ${source}/src/wayland/hyprland/ipc/hyprland-toplevel-mapping-v1.xml \
    ${source}/src/wayland/screencopy/hyprland_screencopy/hyprland-toplevel-export-v1.xml
  cp ${../home/scripts/preview_capture.py} "$out/lib/preview_capture.py"
  makeWrapper ${python}/bin/python "$out/bin/nocturne-preview" \
    --add-flags "$out/lib/preview_capture.py" \
    --prefix PYTHONPATH : "$out/lib"
''
