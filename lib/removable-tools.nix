{ pkgs }:
pkgs.writeShellApplication {
  name = "nocturne-usb";
  runtimeInputs = [ pkgs.python3 ];
  text = ''
    exec python3 ${../home/scripts/removable_media.py} \
      --findmnt ${pkgs.util-linux}/bin/findmnt \
      --sync ${pkgs.coreutils}/bin/sync \
      --udisksctl ${pkgs.udisks}/bin/udisksctl "$@"
  '';
}
