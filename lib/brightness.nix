{ pkgs }:
let
  # Display backlight only: never change a keyboard/status LED by accident.
  # Keep at least one hardware brightness unit so dimming cannot turn it off.
  command = "${pkgs.brightnessctl}/bin/brightnessctl --class=backlight --min-value=1";
in {
  up = "${command} set +5%";
  down = "${command} set 5%-";
}
